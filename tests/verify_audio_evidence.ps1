param(
    [string]$EvidenceDirectory = (Join-Path $PSScriptRoot '..\artifacts\audio_evidence')
)

$ErrorActionPreference = 'Stop'
$expectedRate = 22050
$frequencies = @(40, 58, 80, 118, 173, 245, 490, 820, 1600, 3200, 6400)
$failures = [System.Collections.Generic.List[string]]::new()
$spectra = [System.Collections.Generic.List[object]]::new()

function Get-WavMetadata {
    param([System.IO.FileInfo]$File)

    $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
    if ($bytes.Length -lt 44) {
        return [pscustomobject]@{ File = $File; Bytes = $bytes; Valid = $false; Error = 'header shorter than 44 bytes' }
    }
    $riff = [Text.Encoding]::ASCII.GetString($bytes, 0, 4)
    $wave = [Text.Encoding]::ASCII.GetString($bytes, 8, 4)
    if ($riff -ne 'RIFF' -or $wave -ne 'WAVE') {
        return [pscustomobject]@{ File = $File; Bytes = $bytes; Valid = $false; Error = 'not a RIFF/WAVE file' }
    }

    $format = 0
    $channels = 0
    $rate = 0
    $bits = 0
    $dataOffset = -1
    $dataSize = 0
    $offset = 12
    while ($offset + 8 -le $bytes.Length) {
        $chunkId = [Text.Encoding]::ASCII.GetString($bytes, $offset, 4)
        $chunkSize = [BitConverter]::ToInt32($bytes, $offset + 4)
        $payloadOffset = $offset + 8
        if ($chunkSize -lt 0 -or $payloadOffset + $chunkSize -gt $bytes.Length) { break }
        if ($chunkId -eq 'fmt ' -and $chunkSize -ge 16) {
            $format = [BitConverter]::ToInt16($bytes, $payloadOffset)
            $channels = [BitConverter]::ToInt16($bytes, $payloadOffset + 2)
            $rate = [BitConverter]::ToInt32($bytes, $payloadOffset + 4)
            $bits = [BitConverter]::ToInt16($bytes, $payloadOffset + 14)
        } elseif ($chunkId -eq 'data') {
            $dataOffset = $payloadOffset
            $dataSize = $chunkSize
            break
        }
        $offset = $payloadOffset + $chunkSize + ($chunkSize % 2)
    }
    if ($dataOffset -lt 0 -or $format -ne 1 -or $channels -ne 1 -or $rate -ne $expectedRate -or $bits -ne 16) {
        return [pscustomobject]@{ File = $File; Bytes = $bytes; Valid = $false; Error = "expected mono PCM16/$expectedRate Hz with a data chunk" }
    }
    $sampleCount = [int]($dataSize / 2)
    return [pscustomobject]@{
        File = $File
        Bytes = $bytes
        Valid = $true
        Error = ''
        Rate = $rate
        Channels = $channels
        Bits = $bits
        DataOffset = $dataOffset
        DataSize = $dataSize
        SampleCount = $sampleCount
        Duration = $sampleCount / [double]$rate
    }
}

function Get-SampledSignal {
    param($Wav)

    # Match the deterministic sampling contract written into manifest.json so
    # the independent WAV read can also detect stale or substituted artifacts.
    $stride = [Math]::Max(1, [int][Math]::Ceiling($Wav.SampleCount / 8192.0))
    $sumSquares = 0.0
    $peak = 0.0
    $zeroSamples = 0
    $count = 0
    for ($index = 0; $index -lt $Wav.SampleCount; $index += $stride) {
        $sample = [BitConverter]::ToInt16($Wav.Bytes, $Wav.DataOffset + $index * 2) / 32767.0
        $sumSquares += $sample * $sample
        $peak = [Math]::Max($peak, [Math]::Abs($sample))
        if ([Math]::Abs($sample) -le (1.0 / 32767.0)) { $zeroSamples++ }
        $count++
    }
    return [pscustomobject]@{
        Rms = [Math]::Sqrt($sumSquares / [Math]::Max(1, $count))
        Peak = $peak
        SilenceRatio = $zeroSamples / [double][Math]::Max(1, $count)
        Samples = $count
    }
}

function ConvertTo-Dbfs {
    param([double]$Linear)
    return 20.0 * [Math]::Log10([Math]::Max(0.000000001, $Linear))
}

$manifestPath = Join-Path $EvidenceDirectory 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    [Console]::Error.WriteLine("missing manifest: $manifestPath")
    Write-Output 'HIRING_AUDIO_EVIDENCE_VALIDATION_FAIL'
    exit 1
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

$continuousEntries = @($manifest.continuous_stems)
$foleyEntries = @($manifest.foley)
$chapterEntries = @($manifest.chapters)
$thresholdEntries = @($manifest.thresholds)
$sceneEntries = @($manifest.scenes)
$endingEntries = @($manifest.endings)
$mixEntries = @($chapterEntries) + @($sceneEntries) + @($endingEntries)
$allEntries = @($continuousEntries) + @($foleyEntries) + @($mixEntries)
$quality = $manifest.quality_contract

if ([int]$manifest.schema_version -ne 3) { $failures.Add('manifest schema_version must be 3') }
if ($continuousEntries.Count -ne 8) { $failures.Add("expected 8 continuous stems, found $($continuousEntries.Count)") }
if ($foleyEntries.Count -ne 14) { $failures.Add("expected 14 physical foley streams, found $($foleyEntries.Count)") }
if ($chapterEntries.Count -ne 5) { $failures.Add("expected 5 chapter mixes, found $($chapterEntries.Count)") }
if ($thresholdEntries.Count -ne 5) { $failures.Add("expected 5 threshold target snapshots, found $($thresholdEntries.Count)") }
if ($sceneEntries.Count -ne 17) { $failures.Add("expected 17 narrative scene mixes, found $($sceneEntries.Count)") }
if ($endingEntries.Count -ne 7) { $failures.Add("expected 7 ending mixes, found $($endingEntries.Count)") }

$expectedContinuousIds = @('air', 'rain', 'server_fan', 'distant_voices', 'keyboard_loose', 'keyboard_sync', 'score_human', 'score_system')
$expectedFoleyIds = @('confirm', 'page', 'blocked', 'signature', 'terminal', 'curtain', 'door', 'footstep', 'switch', 'cup', 'projector', 'phone', 'server_stop', 'gpu_start')
$actualContinuousIds = @($continuousEntries | ForEach-Object { [string]$_.id })
$actualFoleyIds = @($foleyEntries | ForEach-Object { [string]$_.id })
$missingContinuousIds = @($expectedContinuousIds | Where-Object { $_ -notin $actualContinuousIds })
$missingFoleyIds = @($expectedFoleyIds | Where-Object { $_ -notin $actualFoleyIds })
if ($missingContinuousIds.Count -gt 0) { $failures.Add("missing continuous stems: $($missingContinuousIds -join ', ')") }
if ($missingFoleyIds.Count -gt 0) { $failures.Add("missing foley streams: $($missingFoleyIds -join ', ')") }

$targetNames = @('air', 'rain', 'server_fan', 'distant_voices', 'keyboard_loose', 'keyboard_sync', 'score_human', 'score_system')
foreach ($snapshot in @($thresholdEntries) + @($mixEntries)) {
    $target = $snapshot.target_db
    $presentNames = @($target.psobject.Properties.Name)
    $missingTargetNames = @($targetNames | Where-Object { $_ -notin $presentNames })
    if ($missingTargetNames.Count -gt 0) {
        $failures.Add("$($snapshot.id): target snapshot missing $($missingTargetNames -join ', ')")
    }
}

$expectedByFile = @{}
foreach ($entry in $continuousEntries) {
    $expectedByFile[[string]$entry.file] = [pscustomobject]@{
        Duration = [double]$entry.duration_seconds
        ExpectSignal = $true
        Category = [string]$entry.category
        Id = [string]$entry.id
        ManifestSummary = $entry.summary
    }
    $expectedBus = if ([string]$entry.category -eq 'score') { 'Music' } else { 'Ambience' }
    if ([string]$entry.bus -ne $expectedBus) { $failures.Add("$($entry.id): expected $expectedBus bus, found $($entry.bus)") }
    if (-not [bool]$entry.looping) { $failures.Add("$($entry.id): continuous stem must loop") }
    $expectedDuration = if ([string]$entry.category -eq 'score') { 48.0 } else { 12.0 }
    if ([Math]::Abs([double]$entry.duration_seconds - $expectedDuration) -gt 0.001) {
        $failures.Add("$($entry.id): expected $expectedDuration-second $($entry.category) source")
    }
    if ([string]$entry.category -eq 'score' -and [double]$entry.summary.silence_ratio -gt [double]$quality.score_max_silence_ratio) {
        $failures.Add("$($entry.id): score duty cycle regressed; silence ratio is $($entry.summary.silence_ratio)")
    }
}
foreach ($entry in $foleyEntries) {
    $expectedByFile[[string]$entry.file] = [pscustomobject]@{
        Duration = [double]$entry.duration_seconds
        ExpectSignal = $true
        Category = 'foley'
        Id = [string]$entry.id
        ManifestSummary = $entry.summary
    }
    if ([string]$entry.bus -ne 'Foley') { $failures.Add("$($entry.id): expected Foley bus, found $($entry.bus)") }
    if ([bool]$entry.looping) { $failures.Add("$($entry.id): physical foley must be non-looping") }
    if ([double]$entry.gain_db -lt -12.0 -or [double]$entry.gain_db -gt -4.0) {
        $failures.Add("$($entry.id): foley playback gain is outside the audible/headroom design range")
    }
    $gain = [Math]::Pow(10.0, [double]$entry.gain_db / 20.0)
    $expectedRenderedRms = [double]$entry.source_summary.rms * $gain
    $expectedRenderedPeak = [double]$entry.source_summary.peak * $gain
    if ([Math]::Abs([double]$entry.summary.rms - $expectedRenderedRms) -gt 0.0002 -or
        [Math]::Abs([double]$entry.summary.peak - $expectedRenderedPeak) -gt 0.0002) {
        $failures.Add("$($entry.id): evidence WAV does not include its production playback gain")
    }
}
foreach ($entry in $mixEntries) {
    $expectedByFile[[string]$entry.file] = [pscustomobject]@{
        Duration = [double]$entry.duration_seconds
        ExpectSignal = [bool]$entry.expect_signal
        Category = 'mix'
        Id = [string]$entry.id
        ManifestSummary = $entry.summary
    }
    if ([int]$entry.automatic_foley_count_delta -ne 0) {
        $failures.Add("$($entry.id): scene/context transition auto-fired foley")
    }
}

$wavFiles = @(Get-ChildItem -LiteralPath $EvidenceDirectory -Filter '*.wav' | Sort-Object Name)
$actualNames = @($wavFiles | ForEach-Object Name)
$expectedNames = @($expectedByFile.Keys)
$missing = @($expectedNames | Where-Object { $_ -notin $actualNames })
$orphan = @($actualNames | Where-Object { $_ -notin $expectedNames })
if ($wavFiles.Count -ne $expectedByFile.Count) { $failures.Add("expected $($expectedByFile.Count) WAV files, found $($wavFiles.Count)") }
if ($missing.Count -gt 0) { $failures.Add("missing manifest references: $($missing -join ', ')") }
if ($orphan.Count -gt 0) { $failures.Add("orphan WAVs: $($orphan -join ', ')") }

$wavByName = @{}
$signalByName = @{}
foreach ($file in $wavFiles) {
    $wav = Get-WavMetadata -File $file
    $wavByName[$file.Name] = $wav
    if (-not $wav.Valid) {
        $failures.Add("$($file.Name): $($wav.Error)")
        continue
    }
    if (-not $expectedByFile.ContainsKey($file.Name)) { continue }
    $expected = $expectedByFile[$file.Name]
    if ([Math]::Abs($wav.Duration - $expected.Duration) -gt 0.002) {
        $failures.Add("$($file.Name): expected $($expected.Duration) sec, found $($wav.Duration)")
    }
    $signal = Get-SampledSignal -Wav $wav
    $signalByName[$file.Name] = $signal
    if ([Math]::Abs($signal.Rms - [double]$expected.ManifestSummary.rms) -gt 0.0002 -or
        [Math]::Abs($signal.Peak - [double]$expected.ManifestSummary.peak) -gt 0.0002) {
        $failures.Add("$($file.Name): measured RMS/peak does not match the manifest")
    }
    if ($expected.ExpectSignal -and ($signal.Rms -le 0.000001 -or $signal.Peak -le 0.00001)) {
        $failures.Add("$($file.Name): expected generated signal, measured silence")
    }
    if (-not $expected.ExpectSignal -and $signal.Peak -gt 0.000001) {
        $failures.Add("$($file.Name): authored silence contains signal")
    }
    if ($expected.Category -eq 'score') {
        if ($signal.SilenceRatio -gt [double]$quality.score_max_silence_ratio) {
            $failures.Add("$($file.Name): rendered score duty cycle is too sparse ($($signal.SilenceRatio) silence)")
        }
        if ($signal.Rms -lt 0.01 -or $signal.Peak -gt 0.40) {
            $failures.Add("$($file.Name): score source is outside the audible/headroom RMS/peak range")
        }
    } elseif ($expected.Category -eq 'foley') {
        if ($signal.Rms -lt [double]$quality.foley_rendered_rms_min -or
            $signal.Rms -gt [double]$quality.foley_rendered_rms_max -or
            $signal.Peak -lt [double]$quality.foley_rendered_peak_min -or
            $signal.Peak -gt [double]$quality.foley_rendered_peak_max) {
            $failures.Add("$($file.Name): rendered foley is not both audible and headroom-safe (RMS=$($signal.Rms), peak=$($signal.Peak))")
        }
    } elseif ($expected.Category -eq 'mix' -and $expected.ExpectSignal) {
        if ($signal.Rms -lt [double]$quality.audible_mix_rms_min -or
            $signal.Peak -lt [double]$quality.audible_mix_peak_min -or
            $signal.Peak -gt [double]$quality.mix_peak_max) {
            $failures.Add("$($file.Name): rendered mix is not both audible and headroom-safe (RMS=$($signal.Rms), peak=$($signal.Peak))")
        }
    }
}

# Produce comparable Goertzel evidence for every continuous source. The human
# theme starts with the title; the system stem's deliberately slow bloom begins
# 0.7 seconds in, so its window starts there instead of in the pre-attack lead-in.
foreach ($entry in $continuousEntries) {
    $wav = $wavByName[[string]$entry.file]
    if ($null -eq $wav -or -not $wav.Valid) { continue }
    $analysisStart = switch ([string]$entry.id) {
        'score_human' { 0.0 }
        'score_system' { 0.7 }
        default { 0.0 }
    }
    $startSample = [Math]::Min($wav.SampleCount - 1, [int]($analysisStart * $expectedRate))
    $sampleCount = [Math]::Min($expectedRate * 4, $wav.SampleCount - $startSample)
    $samples = [double[]]::new($sampleCount)
    $sumSquares = 0.0
    for ($index = 0; $index -lt $sampleCount; $index++) {
        $sample = [BitConverter]::ToInt16($wav.Bytes, $wav.DataOffset + ($startSample + $index) * 2) / 32768.0
        $samples[$index] = $sample
        $sumSquares += $sample * $sample
    }
    $rms = [Math]::Sqrt($sumSquares / [Math]::Max(1, $sampleCount))
    if ($rms -le 0.000001) { $failures.Add("$($entry.id): analysis window has no measurable signal") }
    foreach ($frequency in $frequencies) {
        $omega = 2.0 * [Math]::PI * $frequency / $expectedRate
        $coefficient = 2.0 * [Math]::Cos($omega)
        $previous = 0.0
        $previous2 = 0.0
        foreach ($sample in $samples) {
            $current = $sample + $coefficient * $previous - $previous2
            $previous2 = $previous
            $previous = $current
        }
        $power = $previous2 * $previous2 + $previous * $previous - $coefficient * $previous * $previous2
        $magnitude = [Math]::Sqrt([Math]::Max(0.0, $power)) / [Math]::Max(1, $sampleCount)
        $spectra.Add([pscustomobject]@{
            stem = [string]$entry.id
            category = [string]$entry.category
            bus = [string]$entry.bus
            frequency_hz = $frequency
            magnitude = $magnitude
            rms = $rms
            analysis_start_seconds = $analysisStart
            analysis_seconds = $sampleCount / [double]$expectedRate
        })
    }
}

$sceneById = @{}
foreach ($scene in $sceneEntries) { $sceneById[[string]$scene.id] = $scene }
foreach ($requiredScene in @('title', 'onboarding', 'opening_arrival', 'opening_power', 'opening_handoff', 'full_silence', 'room_tone_only', 'night_shift_1', 'night_shift_2', 'phantom_employee_no_cue', 'final_silence', 'rm_rf_shutdown')) {
    if (-not $sceneById.ContainsKey($requiredScene)) { $failures.Add("missing narrative scene evidence: $requiredScene") }
}
foreach ($openingScene in @('title', 'onboarding')) {
    if ($sceneById.ContainsKey($openingScene)) {
        $targets = $sceneById[$openingScene].target_db
        if ([double]$targets.rain -le -80.0 -or [double]$targets.score_human -le -80.0) {
            $failures.Add("$openingScene must prove audible rain plus the human score")
        }
        if ([double]$targets.distant_voices -gt -80.0 -or [double]$targets.keyboard_loose -gt -80.0 -or [double]$targets.keyboard_sync -gt -80.0) {
            $failures.Add("$openingScene must not leak settled-office voices or keyboards")
        }
    }
}
if ($sceneById.ContainsKey('opening_arrival')) {
    $arrival = $sceneById['opening_arrival'].target_db
    if ([double]$arrival.rain -le -80.0 -or [double]$arrival.score_human -le -80.0 -or [double]$arrival.server_fan -le -80.0) {
        $failures.Add('opening arrival must carry rain, human score, and the running server fan')
    }
}
if ($sceneById.ContainsKey('opening_power')) {
    $power = $sceneById['opening_power'].target_db
    if ([double]$power.rain -le -80.0 -or [double]$power.score_human -le -80.0 -or [double]$power.server_fan -gt -80.0) {
        $failures.Add('opening power failure must retain rain/score while the server fan drops out')
    }
}
if ($sceneById.ContainsKey('opening_handoff')) {
    $handoff = $sceneById['opening_handoff'].target_db
    if ([double]$handoff.rain -le -80.0 -or [double]$handoff.score_human -le -80.0 -or [double]$handoff.server_fan -le -80.0) {
        $failures.Add('opening handoff must restore the server fan under rain and score')
    }
    if ($sceneById.ContainsKey('opening_arrival') -and [double]$handoff.server_fan -le [double]$sceneById['opening_arrival'].target_db.server_fan) {
        $failures.Add('opening handoff fan must return more clearly than its arrival bed')
    }
}
if ($sceneById.ContainsKey('night_shift_1')) {
    $nightOne = $sceneById['night_shift_1'].target_db
    $audibleNightOne = @($nightOne.psobject.Properties | Where-Object { [double]$_.Value -gt -80.0 })
    if ($audibleNightOne.Count -ne 1 -or $audibleNightOne[0].Name -ne 'air') {
        $failures.Add('night_shift_1 must prove HVAC-only ambience')
    }
}
if ($sceneById.ContainsKey('phantom_employee_no_cue') -and [int]$sceneById['phantom_employee_no_cue'].automatic_foley_count_delta -ne 0) {
    $failures.Add('phantom employee context must not emit a cue')
}
if ($sceneById.ContainsKey('rm_rf_shutdown')) {
    if ([double]$sceneById['rm_rf_shutdown'].target_db.server_fan -gt -80.0 -or [double]$sceneById['rm_rf_shutdown'].target_db.air -le -80.0) {
        $failures.Add('rm_rf shutdown must stop server fan while retaining HVAC')
    }
}

$endingHashes = @{}
foreach ($ending in $endingEntries) {
    $endingPath = Join-Path $EvidenceDirectory ([string]$ending.file)
    if (Test-Path -LiteralPath $endingPath) {
        $endingHashes[[string]$ending.id] = (Get-FileHash -LiteralPath $endingPath -Algorithm SHA256).Hash
    }
}
$uniqueEndingHashes = @($endingHashes.Values | Sort-Object -Unique)
if ($uniqueEndingHashes.Count -lt 5) { $failures.Add("ending evidence is insufficiently adaptive: only $($uniqueEndingHashes.Count) unique mixes") }
if ($endingHashes.ContainsKey('rm_rf') -and $endingHashes.ContainsKey('second_time') -and $endingHashes['rm_rf'] -eq $endingHashes['second_time']) {
    $failures.Add('rm_rf and second_time ending mixes must differ')
}

$spectrumPath = Join-Path $EvidenceDirectory 'spectrum.csv'
$spectra | Export-Csv -LiteralPath $spectrumPath -NoTypeInformation -Encoding utf8

$foleySignals = @($foleyEntries | ForEach-Object { $signalByName[[string]$_.file] } | Where-Object { $null -ne $_ })
$audibleMixSignals = @($mixEntries | Where-Object { [bool]$_.expect_signal } | ForEach-Object { $signalByName[[string]$_.file] } | Where-Object { $null -ne $_ })
$scoreDutyCycles = @($continuousEntries | Where-Object { [string]$_.category -eq 'score' } | ForEach-Object { 1.0 - [double]$_.summary.silence_ratio })
if ($foleySignals.Count -gt 0) {
    $foleyRmsMin = [double](($foleySignals | Measure-Object -Property Rms -Minimum).Minimum)
    $foleyRmsMax = [double](($foleySignals | Measure-Object -Property Rms -Maximum).Maximum)
    $foleyPeakMin = [double](($foleySignals | Measure-Object -Property Peak -Minimum).Minimum)
    $foleyPeakMax = [double](($foleySignals | Measure-Object -Property Peak -Maximum).Maximum)
    Write-Output ("FOLEY_RENDERED_RMS_DBFS_RANGE={0:N1}..{1:N1}" -f (ConvertTo-Dbfs $foleyRmsMin), (ConvertTo-Dbfs $foleyRmsMax))
    Write-Output ("FOLEY_RENDERED_PEAK_DBFS_RANGE={0:N1}..{1:N1}" -f (ConvertTo-Dbfs $foleyPeakMin), (ConvertTo-Dbfs $foleyPeakMax))
}
if ($audibleMixSignals.Count -gt 0) {
    $mixRmsMin = [double](($audibleMixSignals | Measure-Object -Property Rms -Minimum).Minimum)
    $mixRmsMax = [double](($audibleMixSignals | Measure-Object -Property Rms -Maximum).Maximum)
    $mixPeakMax = [double](($audibleMixSignals | Measure-Object -Property Peak -Maximum).Maximum)
    Write-Output ("AUDIBLE_MIX_RMS_DBFS_RANGE={0:N1}..{1:N1}" -f (ConvertTo-Dbfs $mixRmsMin), (ConvertTo-Dbfs $mixRmsMax))
    Write-Output ("AUDIBLE_MIX_MAX_PEAK_DBFS={0:N1}" -f (ConvertTo-Dbfs $mixPeakMax))
}
if ($scoreDutyCycles.Count -gt 0) {
    $dutyMin = [double](($scoreDutyCycles | Measure-Object -Minimum).Minimum)
    $dutyMax = [double](($scoreDutyCycles | Measure-Object -Maximum).Maximum)
    Write-Output ("SCORE_DUTY_CYCLE_RANGE={0:P1}..{1:P1}" -f $dutyMin, $dutyMax)
}
foreach ($openingScene in @('title', 'onboarding', 'opening_arrival', 'opening_power', 'opening_handoff')) {
    if ($sceneById.ContainsKey($openingScene)) {
        $openingSignal = $signalByName[[string]$sceneById[$openingScene].file]
        if ($null -ne $openingSignal) {
            Write-Output ("{0}_MIX_DBFS=RMS {1:N1}, PEAK {2:N1}" -f $openingScene.ToUpperInvariant(), (ConvertTo-Dbfs $openingSignal.Rms), (ConvertTo-Dbfs $openingSignal.Peak))
        }
    }
}

Write-Output "WAV_COUNT=$($wavFiles.Count)"
Write-Output "CONTINUOUS_STEM_COUNT=$($continuousEntries.Count)"
Write-Output "FOLEY_COUNT=$($foleyEntries.Count)"
Write-Output "MIX_REFERENCES=$($mixEntries.Count)"
Write-Output "NARRATIVE_SCENE_COUNT=$($sceneEntries.Count)"
Write-Output "UNIQUE_ENDING_MIXES=$($uniqueEndingHashes.Count)"
Write-Output "SPECTRAL_ROWS=$($spectra.Count)"
Write-Output "SPECTRUM_FILE=$spectrumPath"
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { [Console]::Error.WriteLine("HIRING_AUDIO_EVIDENCE_FAILURE: $failure") }
    Write-Output 'HIRING_AUDIO_EVIDENCE_VALIDATION_FAIL'
    exit 1
}
Write-Output 'HIRING_AUDIO_EVIDENCE_VALIDATION_PASS'
