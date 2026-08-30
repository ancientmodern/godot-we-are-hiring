"""Manifest, locality, and readability evidence for the 81-shot UI contract.

Run after hiring_visual_capture.gd. The capture harness freezes HiringMain's
process loop for the copy/theme pairs and pins exact social phase times, so any
extra root PNG or changed pixels outside the declared surfaces are contract
violations. The readability checks deliberately sample text-free blocks and
panel boundaries rather than glyphs or OCR: baked desk texture must not leak
through the dashboard/team reading surfaces, and the settings scrim must
materially suppress both highlights and texture. Archived PNGs are
intentionally outside the root evidence set.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


Rect = tuple[int, int, int, int]


def _xywh(x: int, y: int, width: int, height: int) -> Rect:
    """Convert the Godot Rect2-style geometry used by the UI to PIL bounds."""

    return (x, y, x + width, y + height)


# These are the authored safe surfaces, not inferred bounding boxes. Keeping
# them here makes a shifted/cropped panel fail at its boundary even if a small
# interior sample happens to remain light.
SIDEBAR_SURFACE = _xywh(0, 0, 272, 720)
DASHBOARD_SURFACES: dict[str, Rect] = {
    "main": _xywh(294, 70, 474, 516),
    "toolbar": _xywh(776, 104, 370, 66),
    "detail": _xywh(776, 180, 370, 406),
    "stats": _xywh(294, 594, 852, 72),
}
TEAM_SURFACES: dict[str, Rect] = {
    "main": _xywh(294, 70, 620, 574),
    "right": _xywh(922, 86, 312, 558),
}

DASHBOARD_READABILITY_STEMS = (
    "week_01_dashboard",
    "action_large_train_compute_blocked",
    "office_debt_clear",
    "office_debt_mid",
    "office_debt_high",
)
TEAM_READABILITY_STEMS = (
    "team",
    "team_after_chen_departed",
    "team_before_chen_cups",
    "team_chen_three_cups_active",
    "team_finale_curtain_closed",
    "team_finale_roster_last_page",
    "team_finale_window_open",
    "team_finale_window_reopened",
    "team_phantom_employee",
)

# Text-free gutters are intentional. They remain stable when copy, roster rows,
# page controls, or action availability changes, while still traversing each
# authored reading surface near an edge that previously exposed baked art.
DASHBOARD_CLEAN_PATCHES: dict[str, Rect] = {
    "main": (310, 574, 752, 582),
    "toolbar": (785, 108, 925, 122),
    "detail": (794, 342, 1126, 392),
    "stats": (310, 655, 1130, 662),
}
TEAM_CLEAN_PATCHES: dict[str, Rect] = {
    "main": (540, 608, 730, 624),
    "right": (1222, 160, 1232, 636),
}
SIDEBAR_CLEAN_PATCH = (24, 458, 240, 488)


@dataclass(frozen=True)
class RegionMetrics:
    mean: float
    stddev: float
    p10: int
    p90: int
    texture: float


EXPECTED_CAPTURE_STEMS = frozenset(
    {
        "action_large_train_compute_blocked",
        "announcements",
        "announcements_finale_page_2",
        "announcements_hiring_metrics_hidden",
        "announcements_hiring_metrics_released",
        "announcements_phantom_employee",
        "board_ai_aftermath",
        "board_ai_org_chart",
        "board_ai_page_change",
        "calendar",
        "calendar_extra_floor_contract",
        "calendar_supernatural_resources",
        "ending_acquihire",
        "ending_drift",
        "ending_independent",
        "ending_lights_out",
        "ending_rm_rf",
        "ending_second_time",
        "ending_successor",
        "event_first_investor_meeting_assistant_voice",
        "event_first_investor_meeting_cafe",
        "intranet_phantom_weekly_report",
        "intranet_phantom_weekly_report_page_2",
        "layoff_social_liked",
        "layoff_social_liked_transition",
        "layoff_social_post",
        "layoff_social_process_promised",
        "layoff_social_reliked",
        "layoff_social_reliked_transition",
        "layoff_social_unliked",
        "layoff_social_unliked_transition",
        "lin_scene_2_first_silence",
        "live_replay_aftermath",
        "live_replay_body_voice",
        "live_replay_client_signed",
        "live_replay_return_client_signed",
        "live_replay_second_viewing",
        "live_replay_we_pause",
        "ng_plus_cup_held",
        "ng_plus_cup_present",
        "ng_plus_cup_window_desk",
        "ng_plus_lin_answered",
        "ng_plus_lin_question",
        "night_1_corridor_first_crossing",
        "night_1_corridor_third_crossing",
        "night_1_opening",
        "night_1_plant_debt_clear",
        "night_1_plant_debt_high",
        "night_1_plant_debt_mid",
        "night_1_whiteboard_scarf_dog",
        "night_2_desk_cup_held",
        "night_2_desk_cup_replaced",
        "night_2_opening",
        "night_2_room_d_light_off",
        "night_2_room_d_projection",
        "night_2_room_d_two_steps_away",
        "night_2_terminal_ctrl_c",
        "night_2_terminal_focused",
        "night_2_terminal_unsent_dialogue",
        "office_debt_clear",
        "office_debt_high",
        "office_debt_mid",
        "onboarding",
        "opening_event",
        "origin_article_second_read",
        "origin_article_third_read_editor",
        "origin_article_unchanged",
        "signature_complete",
        "settings_overlay",
        "settings_reduced_motion",
        "team",
        "team_after_chen_departed",
        "team_before_chen_cups",
        "team_chen_three_cups_active",
        "team_finale_curtain_closed",
        "team_finale_roster_last_page",
        "team_finale_window_open",
        "team_finale_window_reopened",
        "team_phantom_employee",
        "terminal",
        "week_01_dashboard",
    }
)
EXPECTED_CAPTURE_COUNT = 81


def _assert_capture_root_manifest(shots: Path) -> int:
    if len(EXPECTED_CAPTURE_STEMS) != EXPECTED_CAPTURE_COUNT:
        raise AssertionError(
            "visual contract has an invalid capture manifest: "
            f"{len(EXPECTED_CAPTURE_STEMS)} unique stems, expected {EXPECTED_CAPTURE_COUNT}"
        )
    if not shots.is_dir():
        raise AssertionError(f"screenshot root does not exist: {shots}")

    root_pngs = sorted(
        path for path in shots.iterdir() if path.is_file() and path.suffix.lower() == ".png"
    )
    actual_stems = {path.stem for path in root_pngs}
    missing = sorted(EXPECTED_CAPTURE_STEMS - actual_stems)
    extra = sorted(actual_stems - EXPECTED_CAPTURE_STEMS)
    if len(root_pngs) != EXPECTED_CAPTURE_COUNT or missing or extra:
        raise AssertionError(
            "screenshot root does not match the 81-stem capture manifest: "
            f"actual_pngs={len(root_pngs)}, missing={missing}, extra={extra}"
        )
    return len(root_pngs)


def _load_rgb(path: Path, label: str) -> Image.Image:
    image = Image.open(path).convert("RGB")
    if image.size != (1280, 720):
        raise AssertionError(
            f"{label}: readability coordinates require 1280x720, found {image.size}"
        )
    return image


def _rect_contains(outer: Rect, inner: Rect) -> bool:
    left, top, right, bottom = outer
    inner_left, inner_top, inner_right, inner_bottom = inner
    return (
        left <= inner_left < inner_right <= right
        and top <= inner_top < inner_bottom <= bottom
    )


def _assert_readability_patch_geometry() -> None:
    for name, patch in DASHBOARD_CLEAN_PATCHES.items():
        if not _rect_contains(DASHBOARD_SURFACES[name], patch):
            raise AssertionError(
                f"dashboard {name} clean patch {patch} escaped {DASHBOARD_SURFACES[name]}"
            )
    for name, patch in TEAM_CLEAN_PATCHES.items():
        if not _rect_contains(TEAM_SURFACES[name], patch):
            raise AssertionError(
                f"team {name} clean patch {patch} escaped {TEAM_SURFACES[name]}"
            )
    if not _rect_contains(SIDEBAR_SURFACE, SIDEBAR_CLEAN_PATCH):
        raise AssertionError(
            f"sidebar clean patch {SIDEBAR_CLEAN_PATCH} escaped {SIDEBAR_SURFACE}"
        )


def _histogram_percentile(histogram: list[int], fraction: float) -> int:
    target = max(1, int(sum(histogram) * fraction + 0.999999))
    cumulative = 0
    for value, count in enumerate(histogram):
        cumulative += count
        if cumulative >= target:
            return value
    return 255


def _region_metrics(image: Image.Image, rect: Rect, label: str) -> RegionMetrics:
    left, top, right, bottom = rect
    if not (0 <= left < right <= image.width and 0 <= top < bottom <= image.height):
        raise AssertionError(f"{label}: invalid sample rectangle {rect} for {image.size}")

    gray = image.convert("L").crop(rect)
    if gray.width < 2 or gray.height < 2:
        raise AssertionError(f"{label}: sample rectangle is too small for texture evidence: {rect}")
    stats = ImageStat.Stat(gray)
    histogram = gray.histogram()
    horizontal = ImageChops.difference(
        gray.crop((0, 0, gray.width - 1, gray.height)),
        gray.crop((1, 0, gray.width, gray.height)),
    )
    vertical = ImageChops.difference(
        gray.crop((0, 0, gray.width, gray.height - 1)),
        gray.crop((0, 1, gray.width, gray.height)),
    )
    texture = (
        ImageStat.Stat(horizontal).mean[0] + ImageStat.Stat(vertical).mean[0]
    ) / 2.0
    return RegionMetrics(
        mean=stats.mean[0],
        stddev=stats.stddev[0],
        p10=_histogram_percentile(histogram, 0.10),
        p90=_histogram_percentile(histogram, 0.90),
        texture=texture,
    )


def _assert_clean_light_surface(
    image: Image.Image, rect: Rect, label: str
) -> RegionMetrics:
    metrics = _region_metrics(image, rect, label)
    spread = metrics.p90 - metrics.p10
    # The authored paper tones are 231-238. The lower bound leaves room for a
    # subtle future grain or color adjustment, but rejects every uncovered
    # baked-paper/desk block from the pre-fix capture (roughly 70-191).
    if metrics.mean < 220.0:
        raise AssertionError(
            f"{label}: reading surface is too dark or absent: mean={metrics.mean:.2f}"
        )
    if metrics.stddev > 2.5 or spread > 6 or metrics.texture > 1.0:
        raise AssertionError(
            f"{label}: baked texture leaks through the clean gutter: "
            f"stddev={metrics.stddev:.2f}, p10-p90={metrics.p10}-{metrics.p90}, "
            f"texture={metrics.texture:.2f}"
        )
    return metrics


def _assert_clean_sidebar(
    image: Image.Image, rect: Rect, label: str
) -> RegionMetrics:
    metrics = _region_metrics(image, rect, label)
    spread = metrics.p90 - metrics.p10
    if metrics.mean > 32.0:
        raise AssertionError(
            f"{label}: sidebar no longer provides a stable dark field: "
            f"mean={metrics.mean:.2f}"
        )
    if metrics.stddev > 2.0 or spread > 6 or metrics.texture > 1.0:
        raise AssertionError(
            f"{label}: background texture leaks through the sidebar: "
            f"stddev={metrics.stddev:.2f}, p10-p90={metrics.p10}-{metrics.p90}, "
            f"texture={metrics.texture:.2f}"
        )
    return metrics


def _assert_edge_step(
    image: Image.Image,
    inside: Rect,
    outside: Rect,
    minimum_step: float,
    label: str,
    *,
    inside_is_lighter: bool = True,
) -> float:
    inside_mean = _region_metrics(image, inside, f"{label} inside").mean
    outside_mean = _region_metrics(image, outside, f"{label} outside").mean
    step = inside_mean - outside_mean
    directed_step = step if inside_is_lighter else -step
    if directed_step < minimum_step:
        direction = "lighter" if inside_is_lighter else "darker"
        raise AssertionError(
            f"{label}: authored surface edge is missing or shifted; expected inside "
            f"to be at least {minimum_step:.1f} levels {direction}, "
            f"inside={inside_mean:.2f}, outside={outside_mean:.2f}"
        )
    return directed_step


def _assert_readability_surfaces(
    shots: Path,
) -> tuple[list[RegionMetrics], list[RegionMetrics], dict[str, float]]:
    _assert_readability_patch_geometry()
    reading_metrics: list[RegionMetrics] = []
    sidebar_metrics: list[RegionMetrics] = []

    for stem in DASHBOARD_READABILITY_STEMS:
        image = _load_rgb(shots / f"{stem}.png", stem)
        for surface, patch in DASHBOARD_CLEAN_PATCHES.items():
            reading_metrics.append(
                _assert_clean_light_surface(
                    image, patch, f"{stem}: dashboard {surface} clean gutter"
                )
            )
        sidebar_metrics.append(
            _assert_clean_sidebar(image, SIDEBAR_CLEAN_PATCH, f"{stem}: sidebar clean gutter")
        )

    for stem in TEAM_READABILITY_STEMS:
        image = _load_rgb(shots / f"{stem}.png", stem)
        for surface, patch in TEAM_CLEAN_PATCHES.items():
            reading_metrics.append(
                _assert_clean_light_surface(
                    image, patch, f"{stem}: team {surface} clean gutter"
                )
            )
        sidebar_metrics.append(
            _assert_clean_sidebar(image, SIDEBAR_CLEAN_PATCH, f"{stem}: sidebar clean gutter")
        )

    dashboard = _load_rgb(shots / "week_01_dashboard.png", "week_01_dashboard")
    team = _load_rgb(shots / "team.png", "team")
    edge_steps = {
        "dashboard_main_bottom": _assert_edge_step(
            dashboard,
            (310, 574, 752, 582),
            (310, 588, 752, 592),
            60.0,
            "dashboard main bottom edge",
        ),
        "dashboard_toolbar_top": _assert_edge_step(
            dashboard,
            (785, 108, 925, 122),
            (785, 92, 925, 100),
            60.0,
            "dashboard toolbar top edge",
        ),
        "dashboard_detail_right": _assert_edge_step(
            dashboard,
            (1136, 342, 1144, 390),
            (1150, 342, 1158, 390),
            80.0,
            "dashboard detail right edge",
        ),
        "dashboard_stats_bottom": _assert_edge_step(
            dashboard,
            (400, 655, 1040, 662),
            (400, 670, 1040, 676),
            60.0,
            "dashboard stats bottom edge",
        ),
        "team_main_bottom": _assert_edge_step(
            team,
            (540, 632, 730, 640),
            (540, 648, 730, 656),
            60.0,
            "team main bottom edge",
        ),
        "team_right_right": _assert_edge_step(
            team,
            (1222, 160, 1232, 290),
            (1238, 160, 1248, 290),
            80.0,
            "team right panel edge",
        ),
        "sidebar_right": _assert_edge_step(
            dashboard,
            (258, 458, 268, 488),
            (278, 458, 288, 488),
            40.0,
            "sidebar right edge",
            inside_is_lighter=False,
        ),
    }
    return reading_metrics, sidebar_metrics, edge_steps


def _assert_settings_scrim(shots: Path) -> list[tuple[float, float, float]]:
    baseline = _load_rgb(shots / "week_01_dashboard.png", "week_01_dashboard")
    # All samples are wholly outside the settings sheet. The right-hand block
    # contains bright reading paper; the other two prove that dark chrome is
    # also flattened instead of retaining distracting fine texture.
    samples: dict[str, Rect] = {
        "top_outer": (8, 8, 342, 68),
        "right_outer": (934, 180, 1272, 620),
        "sidebar_outer": (8, 184, 272, 560),
    }
    ratios: list[tuple[float, float, float]] = []
    for stem in ("settings_overlay", "settings_reduced_motion"):
        overlay = _load_rgb(shots / f"{stem}.png", stem)
        for sample_name, rect in samples.items():
            base_metrics = _region_metrics(
                baseline, rect, f"settings baseline {sample_name}"
            )
            overlay_metrics = _region_metrics(
                overlay, rect, f"{stem} {sample_name}"
            )
            mean_ratio = overlay_metrics.mean / max(base_metrics.mean, 1.0)
            highlight_ratio = overlay_metrics.p90 / max(float(base_metrics.p90), 1.0)
            texture_ratio = overlay_metrics.texture / max(base_metrics.texture, 0.01)

            # A colored scrim has a deliberate dark floor, so ratios alone are
            # misleading over an already-dark sidebar. Pair relative limits
            # with absolute caps; bright paper still has to fall dramatically.
            mean_limit = max(22.0, base_metrics.mean * 0.40)
            highlight_limit = max(24.0, base_metrics.p90 * 0.34)
            if overlay_metrics.mean > mean_limit:
                raise AssertionError(
                    f"{stem} {sample_name}: scrim leaves background too bright: "
                    f"mean={overlay_metrics.mean:.2f}, limit={mean_limit:.2f}, "
                    f"ratio={mean_ratio:.3f}"
                )
            if overlay_metrics.p90 > highlight_limit:
                raise AssertionError(
                    f"{stem} {sample_name}: scrim leaves highlights too bright: "
                    f"p90={overlay_metrics.p90}, limit={highlight_limit:.2f}, "
                    f"ratio={highlight_ratio:.3f}"
                )
            if texture_ratio > 0.35:
                raise AssertionError(
                    f"{stem} {sample_name}: scrim does not suppress background texture: "
                    f"base={base_metrics.texture:.2f}, overlay={overlay_metrics.texture:.2f}, "
                    f"ratio={texture_ratio:.3f}"
                )
            ratios.append((mean_ratio, highlight_ratio, texture_ratio))
    return ratios


def _inside(x: int, y: int, rects: list[Rect]) -> bool:
    return any(left <= x < right and top <= y < bottom for left, top, right, bottom in rects)


def _diff_contract(before_path: Path, after_path: Path, allowed: list[Rect], label: str) -> int:
    before = Image.open(before_path).convert("RGBA")
    after = Image.open(after_path).convert("RGBA")
    if before.size != after.size:
        raise AssertionError(f"{label}: dimensions differ: {before.size} vs {after.size}")

    changed = 0
    leaked: list[tuple[int, int]] = []
    width, height = before.size
    before_pixels = before.load()
    after_pixels = after.load()
    for y in range(height):
        for x in range(width):
            a = before_pixels[x, y]
            b = after_pixels[x, y]
            # Ignore a single quantization level while retaining antialiased glyphs.
            if max(abs(a[channel] - b[channel]) for channel in range(4)) <= 1:
                continue
            changed += 1
            if not _inside(x, y, allowed) and len(leaked) < 20:
                leaked.append((x, y))
    if changed < 40:
        raise AssertionError(f"{label}: expected a visible change, found only {changed} pixels")
    if leaked:
        raise AssertionError(f"{label}: pixels changed outside the approved surface: {leaked}")
    return changed


def _assert_floor_theme_matches(after_path: Path) -> None:
    image = Image.open(after_path).convert("RGBA")
    pixels = image.load()
    origins = [(994, 446), (1048, 446), (1102, 446)]
    # Samples avoid the centered L/1/2 glyph while covering fill, edge and corner.
    offsets = [(6, 6), (21, 6), (35, 7), (6, 21), (35, 21), (8, 35), (34, 34)]
    for dx, dy in offsets:
        samples = [pixels[x + dx, y + dy] for x, y in origins]
        if not samples[0] == samples[1] == samples[2]:
            raise AssertionError(
                "extra elevator floor does not share the ordinary button theme "
                f"at offset {(dx, dy)}: {samples}"
            )


def _changed_pixels_in_rect(before_path: Path, after_path: Path, rect: Rect, label: str) -> int:
    before = Image.open(before_path).convert("RGBA")
    after = Image.open(after_path).convert("RGBA")
    if before.size != after.size:
        raise AssertionError(f"{label}: dimensions differ: {before.size} vs {after.size}")
    left, top, right, bottom = rect
    before_pixels = before.load()
    after_pixels = after.load()
    changed = 0
    for y in range(top, bottom):
        for x in range(left, right):
            a = before_pixels[x, y]
            b = after_pixels[x, y]
            if max(abs(a[channel] - b[channel]) for channel in range(4)) > 1:
                changed += 1
    if changed < 20:
        raise AssertionError(f"{label}: expected animated heart pixels, found only {changed}")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--screenshots",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "artifacts" / "screenshots",
    )
    args = parser.parse_args()
    shots: Path = args.screenshots
    capture_count = _assert_capture_root_manifest(shots)
    reading_metrics, sidebar_metrics, edge_steps = _assert_readability_surfaces(shots)
    scrim_ratios = _assert_settings_scrim(shots)

    option_changed = _diff_contract(
        shots / "event_first_investor_meeting_cafe.png",
        shots / "event_first_investor_meeting_assistant_voice.png",
        [
            (88, 510, 742, 558),
            (88, 564, 742, 612),
            (88, 618, 742, 666),
        ],
        "stage-three option voice",
    )
    floor_changed = _diff_contract(
        shots / "calendar.png",
        shots / "calendar_extra_floor_contract.png",
        [(1098, 442, 1148, 492)],
        "extra elevator floor",
    )
    _assert_floor_theme_matches(shots / "calendar_extra_floor_contract.png")

    heart_rect = (748, 416, 806, 474)
    social_allowed = [heart_rect, (764, 562, 1058, 616)]
    social_animation_pixels: list[int] = []
    for phase in ("liked", "unliked", "reliked"):
        transition = shots / f"layoff_social_{phase}_transition.png"
        settled = shots / f"layoff_social_{phase}.png"
        _diff_contract(transition, settled, social_allowed, f"layoff social {phase} animation")
        social_animation_pixels.append(
            _changed_pixels_in_rect(transition, settled, heart_rect, f"layoff social {phase} heart")
        )

    minimum_surface_luma = min(metric.mean for metric in reading_metrics)
    maximum_surface_stddev = max(metric.stddev for metric in reading_metrics)
    maximum_surface_texture = max(metric.texture for metric in reading_metrics)
    maximum_sidebar_stddev = max(metric.stddev for metric in sidebar_metrics)
    minimum_edge_step = min(edge_steps.values())
    # samples are ordered top/right/sidebar for each of the two settings shots;
    # report the bright-paper ratios, where relative dimming is meaningful.
    bright_scrim_ratios = scrim_ratios[1::3]
    maximum_scrim_bright_mean_ratio = max(ratio[0] for ratio in bright_scrim_ratios)
    maximum_scrim_bright_highlight_ratio = max(
        ratio[1] for ratio in bright_scrim_ratios
    )
    maximum_scrim_texture_ratio = max(ratio[2] for ratio in scrim_ratios)

    print(
        "HIRING_UI_VISUAL_CONTRACT_PASS: "
        f"option_glyph_pixels={option_changed}, extra_floor_pixels={floor_changed}, "
        f"social_heart_pixels={social_animation_pixels}, "
        f"capture_root_pngs={capture_count}, "
        f"reading_surface_patches={len(reading_metrics)}, "
        f"reading_surface_min_luma={minimum_surface_luma:.1f}, "
        f"reading_surface_max_stddev={maximum_surface_stddev:.2f}, "
        f"reading_surface_max_texture={maximum_surface_texture:.2f}, "
        f"sidebar_patches={len(sidebar_metrics)}, "
        f"sidebar_max_stddev={maximum_sidebar_stddev:.2f}, "
        f"boundary_checks={len(edge_steps)}, boundary_min_step={minimum_edge_step:.1f}, "
        f"scrim_samples={len(scrim_ratios)}, "
        f"scrim_bright_max_mean_ratio={maximum_scrim_bright_mean_ratio:.3f}, "
        f"scrim_bright_max_highlight_ratio={maximum_scrim_bright_highlight_ratio:.3f}, "
        f"scrim_max_texture_ratio={maximum_scrim_texture_ratio:.3f}, "
        "outside_contract_pixels=0, floor_theme_samples=21"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
