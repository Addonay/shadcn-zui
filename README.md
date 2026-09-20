# shadcn-zui

shadcn/ui-styled components for the [ZUI](https://github.com/) framework —
a Zig component library laid out like
[gpui-kit](https://github.com/longbridge/gpui-kit).

```zig
const shadcn = @import("shadcn-zui");
const zui = shadcn.zui;

// in a view's render():
shadcn.Button.init("Save changes")
    .variant(.primary)
    .leadingIcon(.check)
    .onClick(cx.listener(State, save))
    .render();
```

## Components

Each component lives in its own folder (`src/components/<name>/`) and exposes
a builder with chainable setters and `render() zui.Element`:

| Component | Notes |
| --- | --- |
| `Button`, `IconButton` | shadcn variants: primary, secondary, destructive, outline, ghost, link; sm/md/lg/icon sizes |
| `Badge` | primary/secondary/destructive/outline pills, optional leading icon |
| `Card` | header/description/content/footer builder + the dashboard metric card |
| `Avatar`, `AvatarGroup` | initials fallback, circle/square, sm–xl; overlapping stack |
| `Checkbox`, `Switch`, `RadioGroup` | controlled booleans and single choice |
| `Input`, `Textarea` | shadcn chrome (editable text uses zui's `TextField` entity) |
| `Slider` | draggable value control as a zui entity widget (`cx.new(shadcn.Slider, ...)`) |
| `Toggle`, `ToggleGroup`, `ButtonGroup` | pressed states and joined buttons |
| `Tabs`, `Breadcrumb`, `Pagination`, `Stepper` | navigation primitives |
| `Accordion`, `Collapsible`, `ScrollArea`, `Empty` | disclosure and scroll containers |
| `Table`, `DataTable` | allocation-free columns/rows, selection column; sortable header variant |
| `Dialog`, `AlertDialog`, `Sheet` | modal panels with a scrim; rendered through the app root |
| `Popover`, `DropdownMenu`, `Tooltip`, `Toast` | pointer-anchored overlays; apps own position + stack |
| `Command` | command-palette list |
| `Alert`, `Label`, `Kbd`, `Link`, `Skeleton`, `Progress`, `Rating`, `Empty`, `GroupBox`, `DescriptionList`, `CopyButton` | display and status primitives |
| `Separator`, `Spinner`, `Icon`, `Sidebar` | divider, rotating Lucide loader, icon builder, sidebar nav shell |
| `AreaChart`, `BarChart`, `LineChart`, `PieChart` | spline areas, grouped bars, dotted lines, donut wedges |
| `StackedAreaChart`, `StackedBarChart`, `HBarChart`, `ComposedChart` | layered areas/bars, horizontal bars, bars+line |
| `ScatterChart` (bubble mode), `RadarChart`, `GaugeChart`, `Sparkline` | points, polar polygons, 270° gauge, mini line |
| `Heatmap`, `Treemap`, `FunnelChart`, `Candlestick`, `WaterfallChart` | value grids, squarified rects, trapezoid funnel, OHLC candles, running totals |
| `AspectRatio`, `Item`, `Field`, `Tag`, `Timeline`, `Statistic`, `Result`, `Comment`, `Watermark`, `Code`, `Highlight`, `NavLink`, `StatusBar`, `LoadingOverlay`, `Affix`, `Image`, `Shimmer`, `Marker`, `Attachment`, `Bubble`, `Message` | second-wave display set |
| `Select`, `Combobox`, `Autocomplete`, `MultiSelect`, `NumberInput`, `PasswordInput`, `SearchField`, `OtpInput`, `TimeField`, `ColorPicker`, `InputGroup`, `ChoiceCard` | second-wave inputs |
| `Calendar`, `RangeCalendar` | month grid + range picker as zui entity widgets |
| `List`, `Menubar`, `NavigationMenu`, `ContextMenu`, `DropdownButton`, `HoverCard`, `Segmented`, `Fab` | menus and nav |
| `Tree`, `Transfer`, `Resizable`, `Carousel`, `TextView`, `Questionnaire` | structure and flows |

Theme tokens (`theme`) use shadcn/ui CSS-variable names (`background`,
`foreground`, `muted_foreground`, `destructive`, `border`, ...), and `support`
holds the small label/strong/icon text helpers.

The icon catalog bundles all **1830 Lucide icons** by default, with four
swappable packs: **tabler** (5130), **phosphor** (1512), **heroicons**
(324) and **hugeicons** (6026). Generate any pack with
`python3 tools/gen_icons.py --preset <name>` and build with
`zig build -Dicons-preset=tabler` — the comptime switch embeds only the
active pack's SVGs (the default build ships lucide alone). Components and
apps reference icons through **semantic roles** (`icon.semantic.close`,
`icon.semantic.search`, ...) so a preset swap is a build flag, not a code
change.

## Using it from an app

```zon
.dependencies = .{
    .zui = .{ .path = "../zui" },
    .shadcn_zui = .{ .path = "../shadcn-zui" },
},
```

```zig
const zui_dep = b.dependency("zui", .{ .target = target, .optimize = optimize });
const shadcn_dep = b.dependency("shadcn_zui", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("zui", zui_dep.module("zui"));
exe.root_module.addImport("shadcn-zui", shadcn_dep.module("shadcn-zui"));
```

## Development

```sh
zig build test                                  # component unit tests
zig build run-gallery                           # open the component gallery
zig build snapshot-gallery -Dsnapshot-height=3200  # headless PPM render
zig build selftest-gallery                      # headless click-through self-test
python3 tools/gen_icons.py                      # regenerate the icon module
```

The gallery (`examples/gallery/`) is the visual reference: a multi-page app —
a sidebar with one page per component family (buttons, inputs, feedback,
overlays, data, charts, navigation), overlays rendered through the app root.
Its headless self-test drives 31 synthetic clicks through the real event
pipeline (sidebar nav, controls, slider drag, dialog/menu open-close,
table row + pagination, tabs/accordion) and asserts the app state after each.
`docs/component-guide.md` documents the authoring conventions.

Reference material that is not vendored lives in `.references/` (gitignored):
the gpui-kit clone used for structure and assets.

## Credits

- Component design: [shadcn/ui](https://ui.shadcn.com/)
- Structure and icon assets: [gpui-kit](https://github.com/longbridge/gpui-kit)
  (Lucide icons under `src/components/icon/assets/icons`)
- Framework: zui
