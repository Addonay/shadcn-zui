//! shadcn-zui component gallery.
//!
//! Run it with `zig build run-gallery`.
//! Headless snapshot: `zig build snapshot-gallery -Dsnapshot-height=3200`
//! Interaction self-test: `zig build selftest-gallery`
//!
//! The app shell: a sidebar with one page per component family, plus the
//! overlay family (dialog/alert-dialog/sheet/popover/menu/tooltip) that
//! renders through the app root as the last children.

const std = @import("std");
const zui = @import("zui");
const shadcn = @import("shadcn-zui");

const App = zui.App;
const Context = zui.Context;
const Window = zui.Window;
const Element = zui.Element;
const Entity = zui.Entity;

const theme = shadcn.theme;
const support = shadcn.support;
const Input = shadcn.Input;
const Button = shadcn.Button;

const pages = @import("pages.zig");

pub const Page = enum {
    overview,
    buttons,
    inputs,
    feedback,
    overlays,
    data,
    charts,
    navigation,
    extras,

    pub fn title(self: Page) []const u8 {
        return switch (self) {
            .overview => "Overview",
            .buttons => "Buttons",
            .inputs => "Inputs",
            .feedback => "Feedback",
            .overlays => "Overlays",
            .data => "Data",
            .charts => "Charts",
            .navigation => "Navigation",
            .extras => "Extras",
        };
    }
};

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

pub const VISITORS = [_]f32{ 420, 610, 530, 780, 700, 930, 860, 1018, 940, 880, 960, 1020 };
pub const MOBILE = [_]f32{ 180, 260, 220, 340, 300, 420, 380, 470, 430, 400, 450, 480 };
pub const LINE_A = [_]f32{ 120, 210, 180, 280, 240, 330, 300, 360 };
pub const RADAR_A = [_]f32{ 0.9, 0.7, 0.55, 0.85, 0.6, 0.75 };
pub const RADAR_B = [_]f32{ 0.5, 0.85, 0.4, 0.6, 0.75, 0.45 };
pub const SPK = [_]f32{ 3, 5, 4, 7, 6, 9, 8, 11 };
pub const LINE_B = [_]f32{ 60, 90, 150, 130, 200, 170, 240, 220 };

pub const Doc = struct {
    header: []const u8,
    section: []const u8,
    status: []const u8,
    done: bool,
    reviewer: []const u8,
};

pub const DOCS = [_]Doc{
    .{ .header = "Cover page", .section = "Narrative", .status = "Done", .done = true, .reviewer = "Eddie Lake" },
    .{ .header = "Executive summary", .section = "Narrative", .status = "In Process", .done = false, .reviewer = "Eddie Lake" },
    .{ .header = "Technical approach", .section = "Technical", .status = "Done", .done = true, .reviewer = "Jamik Tashpulatov" },
    .{ .header = "Cost estimate", .section = "Financial", .status = "In Process", .done = false, .reviewer = "Assign reviewer" },
};

pub const Metrics = struct {
    pub const items = [_]shadcn.CardMetric{
        .{ .title = "Total Revenue", .value = "$1,250.00", .delta = "+12.5%", .delta_up = true, .foot = "Trending up this month", .foot_up = true, .sub = "Visitors for the last 6 months" },
        .{ .title = "New Customers", .value = "1,234", .delta = "-20%", .delta_up = false, .foot = "Down 20% this period", .foot_up = false, .sub = "Acquisition needs attention" },
        .{ .title = "Active Accounts", .value = "45,678", .delta = "+12.5%", .delta_up = true, .foot = "Strong user retention", .foot_up = true, .sub = "Engagement exceeds targets" },
        .{ .title = "Growth Rate", .value = "4.5%", .delta = "+4.5%", .delta_up = true, .foot = "Steady performance increase", .foot_up = true, .sub = "Meets growth projections" },
    };
};

// ---------------------------------------------------------------------------
// View state
// ---------------------------------------------------------------------------

const sidebar_groups = [_]shadcn.SidebarGroup{
    .{ .title = "Getting started", .items = &.{
        .{ .label = "Overview", .icon = .house },
    } },
    .{ .title = "Components", .items = &.{
        .{ .label = "Buttons", .icon = .square_mouse_pointer },
        .{ .label = "Inputs", .icon = .text_cursor },
        .{ .label = "Feedback", .icon = .bell },
        .{ .label = "Overlays", .icon = .app_window },
        .{ .label = "Data", .icon = .table },
        .{ .label = "Charts", .icon = .chart_pie },
        .{ .label = "Navigation", .icon = .compass },
        .{ .label = "Extras", .icon = .layout_dashboard },
    } },
};

pub const Gallery = struct {
    pub const Options = struct {};

    page: Page = .overview,

    // Controls state.
    checked: [2]bool = .{ true, false },
    flags: [3]bool = .{ true, false, true },
    tab: usize = 0,
    rows_checked: [DOCS.len]bool = std.mem.zeroes([DOCS.len]bool),
    clicks: u32 = 0,
    click_buf: [32]u8 = undefined,
    click_label: []const u8 = "Clicked 0 times",
    copied: bool = false,
    radio: usize = 1,
    view_mode: usize = 0,
    toggles: [2]bool = .{ true, false },
    rating: f32 = 3,
    rating_listeners: [5]zui.Listener = undefined,
    accordion_open: [3]bool = .{ true, false, false },
    collapse_open: bool = false,
    command_hover: usize = 2,
    page_num: usize = 5,
    page_labels: [7][8]u8 = undefined,
    sort_col: ?usize = null,
    sort_order: shadcn.components.data_table.SortState = .none,
    slider: Entity(shadcn.Slider),
    slider_buf: [16]u8 = undefined,
    slider_label: []const u8 = "",

    // Animation + charts.
    spinner: shadcn.Spinner = .{},
    spinner_lg: shadcn.Spinner = .{},
    area_buf: [32768]u8 = undefined,
    bar_buf: [16384]u8 = undefined,
    line_buf: [16384]u8 = undefined,
    pie_buf: [8192]u8 = undefined,

    // Scroll offsets (page + the scroll-area demo).
    scroll_y: f32 = 0,
    scroll_area_offset: f32 = 0,

    // Extras state.
    calendar: Entity(shadcn.Calendar),
    range_calendar: Entity(shadcn.RangeCalendar),
    time_hour: u32 = 9,
    time_minute: u32 = 41,
    segmented: usize = 1,
    scatter_buf: [16384]u8 = undefined,
    scatter_bubble_buf: [16384]u8 = undefined,
    radar_buf: [16384]u8 = undefined,
    gauge_buf: [4096]u8 = undefined,
    heatmap_buf: [8192]u8 = undefined,
    treemap_buf: [8192]u8 = undefined,
    funnel_buf: [4096]u8 = undefined,
    spark_buf: [1024]u8 = undefined,
    candle_buf: [16384]u8 = undefined,
    boxplot_buf: [16384]u8 = undefined,
    waterfall_buf: [16384]u8 = undefined,
    stacked_area_buf: [32768]u8 = undefined,
    stacked_bar_buf: [32768]u8 = undefined,
    hbar_buf: [16384]u8 = undefined,
    composed_buf: [32768]u8 = undefined,

    // Overlay state.
    dialog_open: bool = false,
    alert_open: bool = false,
    sheet_open: bool = false,
    popover_open: bool = false,
    popover_x: f32 = 0,
    popover_y: f32 = 0,
    menu_open: bool = false,
    menu_x: f32 = 0,
    menu_y: f32 = 0,
    tip_open: bool = false,
    tip_x: f32 = 0,
    tip_y: f32 = 0,
    menu_result_buf: [32]u8 = undefined,
    menu_result: []const u8 = "Nothing ran yet",
    toast_count: usize = 0,

    pub fn init(cx: *Context(@This()), _: Options) @This() {
        var state = @This(){ .slider = undefined, .calendar = undefined, .range_calendar = undefined };
        state.slider = cx.new(shadcn.Slider, .{ .min = 0, .max = 100, .value = 40, .step = 0 });
        state.calendar = cx.new(shadcn.Calendar, .{ .view = .{ .year = 2026, .month = 9 } });
        state.range_calendar = cx.new(shadcn.RangeCalendar, .{ .view = .{ .year = 2026, .month = 9 } });
        var index: usize = 0;
        while (index < 5) : (index += 1) {
            state.rating_listeners[index] = cx.listenerWith(usize, @This(), setRating, index + 1);
        }
        return state;
    }

    // -- listeners ----------------------------------------------------------

    pub fn bumpClicks(self: *@This(), cx: *Context(@This())) void {
        self.clicks += 1;
        self.click_label = std.fmt.bufPrint(&self.click_buf, "Clicked {d} times", .{self.clicks}) catch "Clicked";
        cx.notify();
    }

    pub fn markCopied(self: *@This(), cx: *Context(@This())) void {
        self.copied = true;
        cx.notify();
    }

    pub fn flipChecked(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.checked[index] = !self.checked[index];
        cx.notify();
    }

    pub fn flipFlag(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.flags[index] = !self.flags[index];
        cx.notify();
    }

    pub fn setRadio(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.radio = index;
        cx.notify();
    }

    pub fn flipToggle(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.toggles[index] = !self.toggles[index];
        cx.notify();
    }

    pub fn setMode(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.view_mode = index;
        cx.notify();
    }

    pub fn setTab(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.tab = index;
        cx.notify();
    }

    pub fn setRating(self: *@This(), stars: usize, cx: *Context(@This())) void {
        self.rating = @floatFromInt(stars);
        cx.notify();
    }

    pub fn flipAccordion(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.accordion_open[index] = !self.accordion_open[index];
        cx.notify();
    }

    pub fn flipCollapse(self: *@This(), cx: *Context(@This())) void {
        self.collapse_open = !self.collapse_open;
        cx.notify();
    }

    pub fn toggleRowChecked(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.rows_checked[index] = !self.rows_checked[index];
        cx.notify();
    }

    pub fn toggleSort(self: *@This(), column_index: usize, cx: *Context(@This())) void {
        if (self.sort_col == column_index) {
            self.sort_order = if (self.sort_order == .asc) .desc else if (self.sort_order == .desc) .none else .asc;
            if (self.sort_order == .none) self.sort_col = null;
        } else {
            self.sort_col = column_index;
            self.sort_order = .asc;
        }
        cx.notify();
    }

    pub fn setPageNum(self: *@This(), page: usize, cx: *Context(@This())) void {
        self.page_num = page;
        cx.notify();
    }

    pub fn prevPageNum(self: *@This(), cx: *Context(@This())) void {
        if (self.page_num > 1) self.page_num -= 1;
        cx.notify();
    }

    pub fn nextPageNum(self: *@This(), cx: *Context(@This())) void {
        if (self.page_num < 20) self.page_num += 1;
        cx.notify();
    }

    pub fn bumpHour(self: *@This(), delta: i32, cx: *Context(@This())) void {
        self.time_hour = shadcn.components.time_field.wrapAdd(self.time_hour, delta, 24);
        cx.notify();
    }

    pub fn bumpMinute(self: *@This(), delta: i32, cx: *Context(@This())) void {
        self.time_minute = shadcn.components.time_field.wrapAdd(self.time_minute, delta, 60);
        cx.notify();
    }

    pub fn hourUp(self: *@This(), cx: *Context(@This())) void {
        self.bumpHour(1, cx);
    }

    pub fn hourDown(self: *@This(), cx: *Context(@This())) void {
        self.bumpHour(-1, cx);
    }

    pub fn minuteUp(self: *@This(), cx: *Context(@This())) void {
        self.bumpMinute(1, cx);
    }

    pub fn minuteDown(self: *@This(), cx: *Context(@This())) void {
        self.bumpMinute(-1, cx);
    }

    pub fn setSegment(self: *@This(), index: usize, cx: *Context(@This())) void {
        self.segmented = index;
        cx.notify();
    }

    pub fn navTo(self: *@This(), target: Page, cx: *Context(@This())) void {
        self.page = target;
        self.scroll_y = 0;
        cx.notify();
    }

    pub fn openDialog(self: *@This(), cx: *Context(@This())) void {
        self.dialog_open = true;
        cx.notify();
    }

    pub fn closeDialog(self: *@This(), cx: *Context(@This())) void {
        self.dialog_open = false;
        cx.notify();
    }

    pub fn openAlert(self: *@This(), cx: *Context(@This())) void {
        self.alert_open = true;
        cx.notify();
    }

    pub fn closeAlert(self: *@This(), cx: *Context(@This())) void {
        self.alert_open = false;
        cx.notify();
    }

    pub fn openSheet(self: *@This(), cx: *Context(@This())) void {
        self.sheet_open = true;
        cx.notify();
    }

    pub fn closeSheet(self: *@This(), cx: *Context(@This())) void {
        self.sheet_open = false;
        cx.notify();
    }

    pub fn openPopover(self: *@This(), window: *Window, cx: *Context(@This())) void {
        const pointer = window.pointerPosition();
        self.popover_x = pointer.x;
        self.popover_y = pointer.y;
        self.popover_open = true;
        cx.notify();
    }

    pub fn closePopover(self: *@This(), cx: *Context(@This())) void {
        self.popover_open = false;
        cx.notify();
    }

    pub fn openMenu(self: *@This(), window: *Window, cx: *Context(@This())) void {
        const pointer = window.pointerPosition();
        self.menu_x = pointer.x;
        self.menu_y = pointer.y;
        self.menu_open = true;
        cx.notify();
    }

    pub fn closeMenu(self: *@This(), cx: *Context(@This())) void {
        self.menu_open = false;
        cx.notify();
    }

    pub fn runMenuItem(self: *@This(), label: []const u8, cx: *Context(@This())) void {
        self.menu_open = false;
        self.menu_result = std.fmt.bufPrint(&self.menu_result_buf, "Ran: {s}", .{label}) catch "Ran";
        cx.notify();
    }

    pub fn toggleTooltip(self: *@This(), window: *Window, cx: *Context(@This())) void {
        if (self.tip_open) {
            self.tip_open = false;
        } else {
            const pointer = window.pointerPosition();
            self.tip_x = pointer.x;
            self.tip_y = pointer.y;
            self.tip_open = true;
        }
        cx.notify();
    }

    pub fn showToast(self: *@This(), cx: *Context(@This())) void {
        if (self.toast_count < 3) self.toast_count += 1;
        cx.notify();
    }

    pub fn dismissToast(self: *@This(), cx: *Context(@This())) void {
        if (self.toast_count > 0) self.toast_count -= 1;
        cx.notify();
    }

    pub fn onScroll(self: *@This(), window: *Window, cx: *Context(@This())) void {
        const viewport = window.bounds.size.h - 34 - 8 - 48;
        const max = @max(0, self.contentHeight() - viewport);
        self.scroll_y = std.math.clamp(self.scroll_y - window.scrollEvent().dy * 45, 0, max);
        cx.notify();
    }

    pub fn onAreaScroll(self: *@This(), window: *Window, cx: *Context(@This())) void {
        self.scroll_area_offset = shadcn.scroll_area.clamp(
            self.scroll_area_offset - window.scrollEvent().dy * shadcn.scroll_area.wheel_speed,
            12 * 22 + 8,
            200,
        );
        cx.notify();
    }

    pub fn noop(_: *@This(), _: *Context(@This())) void {}

    fn beginDrag(_: *@This(), window: *Window, _: *Context(@This())) void {
        window.startDrag();
    }

    fn closeWindow(_: *@This(), window: *Window, _: *Context(@This())) void {
        window.close();
    }

    fn minimizeWindow(_: *@This(), window: *Window, _: *Context(@This())) void {
        window.minimize();
    }

    fn toggleMaximize(_: *@This(), window: *Window, cx: *Context(@This())) void {
        window.toggleMaximize();
        cx.notify();
    }

    fn contentHeight(_: *const @This()) f32 {
        // Generous clamp; narrow windows wrap more, so erring high keeps the
        // page bottom reachable.
        return 3200;
    }

    // -- render -------------------------------------------------------------

    pub fn render(self: *@This(), window: *Window, cx: *Context(@This())) Element {
        self.spinner_lg = self.spinner_lg.size(24).color(theme.foreground);
        if (window.timeMs() > 0) {
            const phi = @as(f32, @floatFromInt(@mod(window.timeMs(), 800))) / 800.0;
            self.spinner = self.spinner.angle(phi * 360.0);
            window.requestAnimationFrame();
        }
        const win = window.bounds.size;
        const sidebar_width: f32 = 240;
        const body_width = @max(400, win.w - sidebar_width - 32);

        const titlebar = zui.div().flex_row().items_center().h(34).w_full().px(12)
            .bg(theme.page)
            .border_b_1().border_color(theme.border)
            .on_mouse_down(cx.listener(@This(), beginDrag))
            .child(support.label("shadcn-zui", 13, theme.muted))
            .child(zui.spacer())
            .child(controlButton(zui.div().w(12).h(2).rounded_full().bg(theme.body))
                .on_click(cx.listener(@This(), minimizeWindow)))
            .child(controlButton(zui.div().size(10).rounded_lg().border_1().border_color(theme.body))
                .on_click(cx.listener(@This(), toggleMaximize)))
            .child(controlButton(zui.text("✕", .{ .font = theme.font, .size = 12, .line_height = 14, .color = theme.body }))
            .on_click(cx.listener(@This(), closeWindow)));

        // Sidebar: two groups, items wired to page navigation with the
        // active page highlighted.
        var overview_items: [1]shadcn.SidebarItem = .{
            .{ .label = "Overview", .icon = .house, .active = self.page == .overview, .on_click = cx.listenerWith(Page, @This(), navTo, .overview) },
        };
        var component_items: [8]shadcn.SidebarItem = undefined;
        const nav_pages = [_]Page{ .buttons, .inputs, .feedback, .overlays, .data, .charts, .navigation, .extras };
        for (sidebar_groups[1].items, 0..) |item, index| {
            component_items[index] = .{
                .label = item.label,
                .icon = item.icon,
                .active = self.page == nav_pages[index],
                .on_click = cx.listenerWith(Page, @This(), navTo, nav_pages[index]),
            };
        }
        var groups_buf: [2]shadcn.SidebarGroup = .{
            .{ .title = "Getting started", .items = overview_items[0..] },
            .{ .title = "Components", .items = component_items[0..] },
        };

        const sidebar = shadcn.Sidebar.init(groups_buf[0..])
            .brand(.layout_panel_left, "shadcn-zui")
            .render();

        const content = pages.render(self, self.page, body_width, window, cx);

        var page = zui.div().flex_row().w(win.w).h(win.h - 34).bg(theme.background)
            .child(sidebar)
            .child(zui.div().w(win.w - sidebar_width).h_full().scroll_y(self.scroll_y)
            .on_scroll(cx.listener(@This(), onScroll))
            .child(zui.div().flex_col().gap(24).p(16)
            .child(content)));

        // Overlays render last (paint order is z order).
        page = self.appendOverlays(page, cx);
        return zui.div().flex_col().size_full().bg(theme.background)
            .child(titlebar)
            .child(page);
    }

    fn appendOverlays(self: *@This(), page: Element, cx: *Context(@This())) Element {
        var root = page;
        if (self.dialog_open) {
            root = root.child(shadcn.Dialog.init()
                .titleText("Edit profile")
                .description("Make changes to your profile here. Click save when you're done.")
                .content(zui.div().flex_col().gap(12)
                    .child(shadcn.Label.init("Display name").render())
                    .child(Input.init().value("shadcn").render())
                    .child(shadcn.Label.init("Email").render())
                    .child(Input.init().value("shadcn@example.com").render()))
                .footer(zui.div().flex_row().items_center().gap(8)
                    .child(Button.init("Cancel").variant(.outline).onClick(cx.listener(@This(), closeDialog)).render())
                    .child(Button.init("Save changes").variant(.primary).onClick(cx.listener(@This(), closeDialog)).render()))
                .onScrimClick(cx.listener(@This(), closeDialog))
                .render());
        }
        if (self.alert_open) {
            root = root.child(shadcn.AlertDialog.init()
                .titleText("Delete this document?")
                .description("This permanently removes the document and its history. This action cannot be undone.")
                .cancel(Button.init("Cancel").variant(.outline).onClick(cx.listener(@This(), closeAlert)).render())
                .action(Button.init("Delete").variant(.destructive).onClick(cx.listener(@This(), closeAlert)).render())
                .onScrimClick(cx.listener(@This(), closeAlert))
                .render());
        }
        if (self.sheet_open) {
            root = root.child(shadcn.Sheet.init(.right)
                .titleText("Edit profile")
                .description("Changes apply immediately.")
                .content(zui.div().flex_col().gap(12)
                    .child(shadcn.Label.init("Name").render())
                    .child(Input.init().value("shadcn").render())
                    .child(shadcn.Label.init("Role").render())
                    .child(Input.init().value("Maintainer").render()))
                .footer(Button.init("Done").variant(.primary).onClick(cx.listener(@This(), closeSheet)).render())
                .onScrimClick(cx.listener(@This(), closeSheet))
                .render());
        }
        if (self.popover_open) {
            root = root.child(shadcn.Popover.init(self.popover_x, self.popover_y)
                .content(zui.div().flex_col().gap(8)
                    .child(support.strong("Dimensions", 14, theme.foreground))
                    .child(support.label("Set the width and height for this block.", 13, theme.muted_foreground))
                    .child(Button.init("Close").variant(.outline).size(.sm).onClick(cx.listener(@This(), closePopover)).render()))
                .onScrimClick(cx.listener(@This(), closePopover))
                .render());
        }
        if (self.menu_open) {
            var menu_items: [4]shadcn.DropdownMenuItem = .{
                .{ .label = "Duplicate", .icon = .copy, .on_click = cx.listenerWith([]const u8, @This(), runMenuItem, "Duplicate") },
                .{ .label = "Share", .icon = .share, .on_click = cx.listenerWith([]const u8, @This(), runMenuItem, "Share") },
                .{ .kind = .separator },
                .{ .label = "Delete", .icon = .trash, .danger = true, .on_click = cx.listenerWith([]const u8, @This(), runMenuItem, "Delete") },
            };
            root = root.child(shadcn.DropdownMenu.init(menu_items[0..])
                .at(self.menu_x, self.menu_y)
                .onScrimClick(cx.listener(@This(), closeMenu))
                .render());
        }
        if (self.tip_open) {
            root = root.child(shadcn.Tooltip.init("Add to favorites").at(self.tip_x, self.tip_y).position(.bottom).render());
        }
        if (self.toast_count > 0) {
            var stack = zui.div().absolute().right(16).top(8).flex_col().gap(8);
            var shown: usize = 0;
            while (shown < self.toast_count) : (shown += 1) {
                stack = stack.child(shadcn.Toast.init("Changes saved")
                    .description("Your document was updated.")
                    .variant(.success)
                    .onDismiss(cx.listener(@This(), dismissToast))
                    .render());
            }
            root = root.child(stack);
        }
        return root;
    }
};

fn controlButton(glyph: Element) Element {
    return zui.div().size(28).flex_row().items_center().justify_center().rounded_lg()
        .cursor_pointer().hover_bg(theme.accent)
        .child(glyph);
}

// ---------------------------------------------------------------------------
// App wiring
// ---------------------------------------------------------------------------

fn buildRoot(window: *Window, vcx: *Context(Gallery)) Entity(Gallery) {
    _ = window;
    const view = vcx.new(Gallery, .{});
    // Recorded for the self-test and the per-page snapshot overrides.
    selftest_view = view;
    return view;
}

fn onOpen(cx: *App) void {
    const bounds = zui.Bounds.centered(null, zui.size(1400, 1000), cx);
    _ = cx.openWindow(.{
        .bounds = bounds,
        .title = "shadcn-zui gallery",
        .min_size = zui.size(900, 600),
        .chrome = .custom,
    }, buildRoot) catch |err| std.log.err("open window: {s}", .{@errorName(err)});
    cx.activate(true);
}

// ---------------------------------------------------------------------------
// Headless snapshot
// ---------------------------------------------------------------------------

fn snapshotDimension(name: [*:0]const u8, fallback: u32) u32 {
    const raw = std.c.getenv(name) orelse return fallback;
    const value = std.fmt.parseInt(u32, std.mem.span(raw), 10) catch return fallback;
    return if (value >= 100 and value <= 4096) value else fallback;
}

fn snapshotHeadless(gpa: std.mem.Allocator, path: []const u8) !void {
    const width = snapshotDimension("ZUI_SNAPSHOT_WIDTH", 1400);
    const height = snapshotDimension("ZUI_SNAPSHOT_HEIGHT", 1000);
    var app = try App.initHeadless(gpa);
    defer app.deinit();
    const win = try app.openWindow(.{
        .bounds = .{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .w = @floatFromInt(width), .h = @floatFromInt(height) } },
        .title = "shadcn-zui gallery",
        .min_size = zui.size(900, 600),
        .chrome = .custom,
    }, buildRoot);
    // Optional page override for per-page snapshots.
    if (std.c.getenv("ZUI_SNAPSHOT_PAGE")) |raw_page| {
        if (selftest_view) |view| {
            const name = std.mem.span(raw_page);
            view.readMut().page = if (std.mem.eql(u8, name, "buttons"))
                .buttons
            else if (std.mem.eql(u8, name, "inputs"))
                .inputs
            else if (std.mem.eql(u8, name, "feedback"))
                .feedback
            else if (std.mem.eql(u8, name, "overlays"))
                .overlays
            else if (std.mem.eql(u8, name, "data"))
                .data
            else if (std.mem.eql(u8, name, "charts"))
                .charts
            else if (std.mem.eql(u8, name, "navigation"))
                .navigation
            else if (std.mem.eql(u8, name, "extras"))
                .extras
            else
                .overview;
        }
        _ = app.step();
    }
    // Optional overlay pre-open (dialog|alert|sheet|popover|menu|tooltip|toast)
    // for reviewing open overlays and measuring their click coordinates.
    // Pointer-anchored overlays use fixed positions so snapshots are stable.
    if (std.c.getenv("ZUI_SNAPSHOT_OPEN")) |raw_open| {
        if (selftest_view) |view| {
            const state = view.readMut();
            const name = std.mem.span(raw_open);
            if (std.mem.eql(u8, name, "dialog")) {
                state.dialog_open = true;
            } else if (std.mem.eql(u8, name, "alert")) {
                state.alert_open = true;
            } else if (std.mem.eql(u8, name, "sheet")) {
                state.sheet_open = true;
            } else if (std.mem.eql(u8, name, "popover")) {
                state.popover_open = true;
                state.popover_x = 500;
                state.popover_y = 500;
            } else if (std.mem.eql(u8, name, "menu")) {
                state.menu_open = true;
                state.menu_x = 500;
                state.menu_y = 500;
            } else if (std.mem.eql(u8, name, "tooltip")) {
                state.tip_open = true;
                state.tip_x = 500;
                state.tip_y = 500;
            } else if (std.mem.eql(u8, name, "toast")) {
                state.toast_count = 3;
            }
        }
        _ = app.step();
    }
    // Optional scroll offset so below-the-fold sections can be reviewed in
    // tall pages (e.g. ZUI_SNAPSHOT_SCROLL=2500 for the charts page bottom).
    if (std.c.getenv("ZUI_SNAPSHOT_SCROLL")) |raw_scroll| {
        if (selftest_view) |view| {
            const value = std.fmt.parseFloat(f32, std.mem.span(raw_scroll)) catch 0;
            view.readMut().scroll_y = @max(0, value);
        }
        _ = app.step();
    }
    _ = app.step();

    const pixels = try gpa.alloc(u8, @as(usize, width) * height * 4);
    defer gpa.free(pixels);
    var renderer = zui.gpu.vellz.Renderer.init(gpa);
    defer renderer.deinit();
    try renderer.render(pixels, width, height, .rgba32, theme.background, &win.scene, app.glyphPixels(), app.imagePixels());

    const file = file: {
        var path_buf: [4096]u8 = undefined;
        if (path.len >= path_buf.len) return error.NameTooLong;
        @memcpy(path_buf[0..path.len], path);
        path_buf[path.len] = 0;
        const name: [*:0]const u8 = path_buf[0..path.len :0];
        break :file std.c.fopen(name, "wb") orelse return error.CannotOpenSnapshot;
    };
    defer _ = std.c.fclose(file);
    var header_buf: [64]u8 = undefined;
    const header_text = try std.fmt.bufPrint(&header_buf, "P6\n{d} {d}\n255\n", .{ width, height });
    if (std.c.fwrite(header_text.ptr, 1, header_text.len, file) != header_text.len) return error.SnapshotWriteFailed;
    var i: usize = 0;
    while (i < pixels.len) : (i += 4) {
        if (std.c.fwrite(pixels.ptr + i, 1, 3, file) != 3) return error.SnapshotWriteFailed;
    }
}

// ---------------------------------------------------------------------------
// Headless interaction self-test
// ---------------------------------------------------------------------------

var selftest_view: ?Entity(Gallery) = null;

fn selftestBuildRoot(window: *Window, vcx: *Context(Gallery)) Entity(Gallery) {
    const view = buildRoot(window, vcx);
    selftest_view = view;
    return view;
}

fn click(backend: anytype, x: f32, y: f32) void {
    _ = backend.pushEvent(.{ .mouse = .{ .pos = .{ .x = x, .y = y }, .button = .left, .pressed = true } });
    _ = backend.pushEvent(.{ .mouse = .{ .pos = .{ .x = x, .y = y }, .button = .left, .pressed = false } });
}

/// The window's own hit-test rule: topmost (last-painted) region containing
/// the point, or null when the click would land on nothing interactive.
fn topmostRegionAt(win: *Window, x: f32, y: f32) ?zui.elements.HitRegion {
    var i = win.ui_frame.region_count;
    while (i > 0) {
        i -= 1;
        const region = win.ui_frame.regions[i];
        if (region.bounds.contains(.{ .x = x, .y = y })) return region;
    }
    return null;
}

/// Click through the real pipeline, aiming at the region a real pointer click
/// at (x, y) would hit. Clicking the matched region's center keeps small
/// measurement drift harmless. ZUI_SELFTEST_DEBUG=1 logs each match.
fn clickAt(backend: anytype, win: *Window, x: f32, y: f32) void {
    if (topmostRegionAt(win, x, y)) |region| {
        if (std.c.getenv("ZUI_SELFTEST_DEBUG") != null) {
            std.debug.print("clickAt ({d:.0},{d:.0}) -> region ({d:.0},{d:.0})..({d:.0},{d:.0})\n", .{
                x, y, region.bounds.x, region.bounds.y, region.bounds.x + region.bounds.w, region.bounds.y + region.bounds.h,
            });
        }
        click(backend, region.bounds.x + region.bounds.w / 2, region.bounds.y + region.bounds.h / 2);
    } else {
        std.debug.print("clickAt ({d:.0},{d:.0}) -> no region (check will fail)\n", .{ x, y });
        click(backend, x, y);
    }
}

/// Press at `from_x/from_y`, drag to `to_x/to_y` in steps, release. zui's
/// pointer capture keeps move events flowing to the pressed control.
fn drag(backend: anytype, from_x: f32, from_y: f32, to_x: f32, to_y: f32) void {
    _ = backend.pushEvent(.{ .mouse = .{ .pos = .{ .x = from_x, .y = from_y }, .button = .left, .pressed = true } });
    var step_index: usize = 0;
    while (step_index < 4) : (step_index += 1) {
        const t = (@as(f32, @floatFromInt(step_index)) + 1) / 4.0;
        _ = backend.pushEvent(.{ .mouse = .{
            .pos = .{ .x = from_x + (to_x - from_x) * t, .y = from_y + (to_y - from_y) * t },
            .button = .left,
            .pressed = true,
            .motion = true,
        } });
    }
    _ = backend.pushEvent(.{ .mouse = .{ .pos = .{ .x = to_x, .y = to_y }, .button = .left, .pressed = false } });
}

/// Drives synthetic clicks through backend queue -> App -> Window -> hit-test
/// -> listener -> entity and verifies interactive components react.
///   ZUI_SELFTEST=1 zig-out/bin/gallery
/// Coordinates are measured from `zig build snapshot-gallery` runs at the
/// same window size (1400x2400); per-overlay snapshots use ZUI_SNAPSHOT_OPEN.
fn selftestHeadless(gpa: std.mem.Allocator) !void {
    var app = try App.initHeadless(gpa);
    defer app.deinit();
    const win = try app.openWindow(.{
        .bounds = .{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .w = 1400, .h = 2400 } },
        .title = "shadcn-zui gallery",
        .min_size = zui.size(900, 600),
        .chrome = .custom,
    }, selftestBuildRoot);
    _ = app.step(); // initial frame populates hit regions

    const backend = app.getNullBackend() orelse return error.SelftestNeedsNullBackend;
    const view = selftest_view orelse return error.SelftestNoView;

    var failures: u32 = 0;
    var checks: u32 = 0;
    const check = struct {
        fn ok(cond: bool, count: *u32, total: *u32, comptime fmt: []const u8, args: anytype) void {
            total.* += 1;
            if (cond) {
                std.debug.print("selftest PASS: " ++ fmt ++ "\n", args);
            } else {
                std.debug.print("selftest FAIL: " ++ fmt ++ "\n", args);
                count.* += 1;
            }
        }
    }.ok;

    // -- sidebar navigation --
    check(view.read().page == .overview, &failures, &checks, "gallery starts on the overview", .{});

    clickAt(backend, win, 120, 248); // sidebar: Buttons
    _ = app.step();
    check(view.read().page == .buttons, &failures, &checks, "sidebar navigates to Buttons", .{});

    // -- buttons page --
    {
        const state = view.read();
        const clicks_before = state.clicks;
        clickAt(backend, win, 370, 238); // "Primary" variant button
        _ = app.step();
        const state_after = view.read();
        check(state_after.clicks == clicks_before + 1 and std.mem.eql(u8, state_after.click_label, "Clicked 1 times"), &failures, &checks, "primary button increments the click counter", .{});
    }

    clickAt(backend, win, 556, 473); // CopyButton
    _ = app.step();
    check(view.read().copied, &failures, &checks, "copy button marks copied", .{});

    clickAt(backend, win, 414, 701); // "Italic" toggle
    _ = app.step();
    check(view.read().toggles[1], &failures, &checks, "italic toggle turns pressed", .{});

    clickAt(backend, win, 400, 750); // toggle group: Week
    _ = app.step();
    check(view.read().view_mode == 1, &failures, &checks, "toggle group selects Week", .{});

    // -- inputs page --
    clickAt(backend, win, 120, 284); // sidebar: Inputs
    _ = app.step();
    check(view.read().page == .inputs, &failures, &checks, "sidebar navigates to Inputs", .{});

    clickAt(backend, win, 450, 632); // checkbox row "Send me product updates"
    _ = app.step();
    check(view.read().checked[1], &failures, &checks, "checkbox row flips on", .{});

    clickAt(backend, win, 700, 636); // switch row "Notifications"
    _ = app.step();
    check(view.read().flags[1], &failures, &checks, "switch turns on", .{});

    clickAt(backend, win, 335, 945); // radio "Pickup"
    _ = app.step();
    check(view.read().radio == 2, &failures, &checks, "radio selects Pickup", .{});

    clickAt(backend, win, 613, 860); // fifth rating star
    _ = app.step();
    check(view.read().rating == 5, &failures, &checks, "rating star click sets five", .{});

    {
        const value_before = view.read().slider.read().value;
        drag(backend, 457, 1106, 557, 1106); // slider thumb: +100px
        _ = app.step();
        const value_after = view.read().slider.read().value;
        check(value_after > value_before + 20 and value_after < value_before + 45, &failures, &checks, "slider drag raises the value (before {d:.0}, after {d:.0})", .{ value_before, value_after });
    }

    // -- feedback page --
    clickAt(backend, win, 120, 320); // sidebar: Feedback
    _ = app.step();
    check(view.read().page == .feedback, &failures, &checks, "sidebar navigates to Feedback", .{});

    check(view.read().toast_count == 0, &failures, &checks, "toast stack starts empty", .{});
    clickAt(backend, win, 747, 1032); // "Show toast"
    _ = app.step();
    check(view.read().toast_count == 1, &failures, &checks, "show toast pushes one", .{});

    // -- overlays page --
    clickAt(backend, win, 120, 356); // sidebar: Overlays
    _ = app.step();
    check(view.read().page == .overlays, &failures, &checks, "sidebar navigates to Overlays", .{});

    clickAt(backend, win, 385, 238); // "Open dialog"
    _ = app.step();
    check(view.read().dialog_open, &failures, &checks, "Open dialog opens the dialog", .{});

    clickAt(backend, win, 551, 1329); // dialog footer: Cancel
    _ = app.step();
    check(!view.read().dialog_open, &failures, &checks, "dialog Cancel closes it", .{});

    clickAt(backend, win, 520, 593); // "Open menu" (menu anchors at this point)
    _ = app.step();
    check(view.read().menu_open, &failures, &checks, "Open menu opens the dropdown", .{});

    clickAt(backend, win, 580, 655); // menu item Duplicate (anchor + 60,62)
    _ = app.step();
    {
        const state = view.read();
        check(!state.menu_open and std.mem.eql(u8, state.menu_result, "Ran: Duplicate"), &failures, &checks, "menu item runs and closes the menu", .{});
    }

    clickAt(backend, win, 520, 593); // reopen the menu
    _ = app.step();
    check(view.read().menu_open, &failures, &checks, "menu reopens", .{});

    clickAt(backend, win, 100, 1500); // scrim, far from the panel
    _ = app.step();
    check(!view.read().menu_open, &failures, &checks, "clicking outside closes the menu", .{});

    // -- data page --
    clickAt(backend, win, 120, 391); // sidebar: Data
    _ = app.step();
    check(view.read().page == .data, &failures, &checks, "sidebar navigates to Data", .{});

    clickAt(backend, win, 400, 325); // first data-table row
    _ = app.step();
    check(view.read().rows_checked[0], &failures, &checks, "row click selects it", .{});

    check(view.read().page_num == 5, &failures, &checks, "pagination starts on page 5", .{});
    clickAt(backend, win, 1269, 543); // pagination chip "6"
    _ = app.step();
    check(view.read().page_num == 6, &failures, &checks, "pagination chip jumps pages", .{});

    // -- navigation page --
    clickAt(backend, win, 120, 464); // sidebar: Navigation
    _ = app.step();
    check(view.read().page == .navigation, &failures, &checks, "sidebar navigates to Navigation", .{});

    // The link click goes first: opening the accordion or the collapsible
    // below shifts this section down, so it must run on the pristine layout.
    clickAt(backend, win, 650, 1110); // "Documentation" link
    _ = app.step();
    check(view.read().toast_count == 2, &failures, &checks, "link click fires its action", .{});

    clickAt(backend, win, 640, 239); // tab "Key Personnel"
    _ = app.step();
    check(view.read().tab == 2, &failures, &checks, "tab click switches tabs", .{});

    clickAt(backend, win, 388, 620); // collapsible trigger (pristine layout)
    _ = app.step();
    check(view.read().collapse_open, &failures, &checks, "collapsible expands", .{});

    clickAt(backend, win, 400, 515); // accordion item 2
    _ = app.step();
    check(view.read().accordion_open[1], &failures, &checks, "accordion item opens", .{});

    if (failures != 0) return error.SelftestFailed;
    std.debug.print("selftest: all {d} checks passed\n", .{checks});
}

pub fn main(init: std.process.Init) !void {
    if (std.c.getenv("ZUI_SNAPSHOT")) |raw| {
        try snapshotHeadless(init.gpa, std.mem.span(raw));
        return;
    }
    if (std.c.getenv("ZUI_SELFTEST") != null) {
        try selftestHeadless(init.gpa);
        return;
    }
    var app = try App.init(init.gpa);
    defer app.deinit();
    app.run(onOpen);
}

test {
    std.testing.refAllDecls(@This());
}
