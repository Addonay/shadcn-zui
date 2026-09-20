//! Gallery pages: every component family gets its own page. `main.zig`
//! owns the state, the sidebar shell and the overlay family; each `render*`
//! here builds one page's content.

const std = @import("std");
const zui = @import("zui");
const shadcn = @import("shadcn-zui");

const main = @import("main.zig");
const Gallery = main.Gallery;
const Page = main.Page;
const DOCS = main.DOCS;

const theme = shadcn.theme;
const support = shadcn.support;
const icon = shadcn.components.icon;
const semantic = icon.semantic;

const AreaChart = shadcn.AreaChart;
const Avatar = shadcn.Avatar;
const Badge = shadcn.Badge;
const Button = shadcn.Button;
const IconButton = shadcn.IconButton;
const Card = shadcn.Card;
const Checkbox = shadcn.Checkbox;
const Input = shadcn.Input;
const Separator = shadcn.Separator;
const Spinner = shadcn.Spinner;
const Tabs = shadcn.Tabs;
const Table = shadcn.Table;

pub fn render(state: *Gallery, page: Page, body_width: f32, window: *zui.Window, cx: *zui.Context(Gallery)) zui.Element {
    _ = window;
    return switch (page) {
        .overview => overview(state, body_width, cx),
        .buttons => buttons(state, body_width, cx),
        .inputs => inputs(state, body_width, cx),
        .feedback => feedback(state, body_width, cx),
        .overlays => overlays(state, body_width, cx),
        .data => data(state, body_width, cx),
        .charts => charts(state, body_width),
        .navigation => navigation(state, body_width, cx),
        .extras => extras(state, body_width, cx),
    };
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

fn sectionCard(state: *Gallery, title: []const u8, description: []const u8, body: zui.Element) zui.Element {
    _ = state;
    return Card.init()
        .title(title)
        .description(description)
        .content(body)
        .render();
}

fn pageHeader(title: []const u8, description: []const u8, body_width: f32) zui.Element {
    return zui.div().flex_row().items_center().justify_between().w(body_width)
        .child(zui.div().flex_col().gap(4)
        .child(support.strong(title, 24, theme.foreground))
        .child(support.label(description, 14, theme.muted_foreground)));
}

fn pageColumn(sections: []const zui.Element) zui.Element {
    var col = zui.div().flex_col().w_full().gap(24);
    for (sections) |section| col = col.child(section);
    return col;
}

fn rowOf(elements: []const zui.Element, gap: f32) zui.Element {
    var row = zui.div().flex_row().flex_wrap().items_center().gap(gap);
    for (elements) |element| row = row.child(element);
    return row;
}

fn legendDot(color: zui.Color, text: []const u8) zui.Element {
    return zui.div().flex_row().items_center().gap(6)
        .child(zui.div().size(8).rounded_full().bg(color))
        .child(support.label(text, 12, theme.muted_foreground));
}

fn rowWithControl(control: zui.Element, label: []const u8, listener: zui.Listener) zui.Element {
    return zui.div().flex_row().items_center().gap(10).cursor_pointer()
        .on_click(listener)
        .child(control)
        .child(support.label(label, 14, theme.foreground));
}

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

fn overview(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    var metric_row = zui.div().flex_row().flex_wrap().gap(16).w(body_width);
    for (&main.Metrics.items) |*metric| {
        metric_row = metric_row.child(zui.div().flex_1().w(260).child(Card.metric(metric.*)));
    }

    const badges = rowOf(&.{
        Badge.init("Primary").variant(.primary).render(),
        Badge.init("Secondary").variant(.secondary).render(),
        Badge.init("Destructive").variant(.destructive).render(),
        Badge.init("Outline").variant(.outline).render(),
        Badge.init("With icon").variant(.outline).icon(.circle_check).render(),
    }, 8);

    return pageColumn(&.{
        pageHeader("Component gallery", "shadcn/ui-styled components for the ZUI framework", body_width),
        metric_row,
        Card.init()
            .title("Getting around")
            .description("Pick a section in the sidebar; every component family has a page.")
            .content(zui.div().flex_col().gap(12)
                .child(support.label("· Buttons, inputs and feedback primitives have their own pages.", 14, theme.body))
                .child(support.label("· Overlays (dialog, sheet, popover, menu) render through the app root.", 14, theme.body))
                .child(support.label("· Charts and data tables close the set.", 14, theme.body)))
            .render(),
        Card.init()
            .title("Badges")
            .description("Pill labels for counts, states and metadata.")
            .content(badges)
            .render(),
        Card.init()
            .title("Buttons")
            .description("The header action.")
            .content(rowOf(&.{
                Badge.init(state.click_label).variant(.outline).render(),
                Button.init("New document").variant(.primary).leadingIcon(.plus).onClick(cx.listener(Gallery, Gallery.bumpClicks)).render(),
            }, 8))
            .render(),
    });
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

fn buttons(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    const variants = rowOf(&.{
        Button.init("Primary").variant(.primary).onClick(cx.listener(Gallery, Gallery.bumpClicks)).render(),
        Button.init("Secondary").variant(.secondary).render(),
        Button.init("Destructive").variant(.destructive).render(),
        Button.init("Outline").variant(.outline).render(),
        Button.init("Ghost").variant(.ghost).render(),
        Button.init("Link").variant(.link).render(),
        Button.init("Disabled").disabled(true).render(),
    }, 8);

    const sizes = rowOf(&.{
        Button.init("Small").size(.sm).render(),
        Button.init("Default").size(.md).render(),
        Button.init("Large").size(.lg).render(),
        Button.init("With icon").variant(.outline).leadingIcon(.search).render(),
        Button.init("Trailing").variant(.outline).trailingIcon(.chevron_down).render(),
    }, 8);

    const icon_row = rowOf(&.{
        IconButton.init(.plus).variant(.primary).render(),
        IconButton.init(.search).variant(.secondary).render(),
        IconButton.init(.settings).variant(.outline).render(),
        IconButton.init(.ellipsis_vertical).variant(.ghost).render(),
        IconButton.init(.x).variant(.ghost).render(),
    }, 8);

    var copy_button = shadcn.CopyButton.init().onCopy(cx.listener(Gallery, Gallery.markCopied));
    copy_button.copied = state.copied;

    const group = shadcn.ButtonGroup.init(&.{
        Button.init("Left").variant(.outline).render(),
        Button.init("Middle").variant(.outline).render(),
        IconButton.init(.plus).variant(.outline).render(),
    }).render();

    const toggles = rowOf(&.{
        shadcn.Toggle.init("Bold").pressed(state.toggles[0]).onToggle(cx.listenerWith(usize, Gallery, Gallery.flipToggle, 0)).render(),
        shadcn.Toggle.init("Italic").pressed(state.toggles[1]).onToggle(cx.listenerWith(usize, Gallery, Gallery.flipToggle, 1)).render(),
        shadcn.Toggle.iconOnly(.star).pressed(state.toggles[1]).onToggle(cx.listenerWith(usize, Gallery, Gallery.flipToggle, 1)).render(),
    }, 8);

    var toggle_group_items: [3]shadcn.ToggleGroupItem = .{
        .{ .label = "Day", .pressed = state.view_mode == 0, .on_click = cx.listenerWith(usize, Gallery, Gallery.setMode, 0) },
        .{ .label = "Week", .pressed = state.view_mode == 1, .on_click = cx.listenerWith(usize, Gallery, Gallery.setMode, 1) },
        .{ .label = "Month", .pressed = state.view_mode == 2, .on_click = cx.listenerWith(usize, Gallery, Gallery.setMode, 2) },
    };
    const toggle_group = shadcn.ToggleGroup.init(toggle_group_items[0..]).render();

    return pageColumn(&.{
        pageHeader("Buttons", "Every button shape the library ships.", body_width),
        sectionCard(state, "Variants & sizes", "Primary, secondary, destructive, outline, ghost, link; sm/md/lg.", zui.div().flex_col().gap(16)
            .child(variants)
            .child(sizes)),
        sectionCard(state, "Icons & copy", "Icon buttons and the clipboard button.", rowOf(&.{
            icon_row,
            copy_button.render(),
        }, 32)),
        sectionCard(state, "Groups & toggles", "Joined buttons, pressed states, toggle group.", zui.div().flex_col().gap(16)
            .child(group)
            .child(toggles)
            .child(toggle_group)),
    });
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

fn inputs(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    const slider_value = state.slider.read().value;
    state.slider_label = std.fmt.bufPrint(&state.slider_buf, "{d:.0}", .{slider_value}) catch "";

    var radio_items: [3]shadcn.RadioGroupItem = .{
        .{ .label = "Default", .selected = state.radio == 0, .on_click = cx.listenerWith(usize, Gallery, Gallery.setRadio, 0) },
        .{ .label = "Express", .description = "Arrives tomorrow", .selected = state.radio == 1, .on_click = cx.listenerWith(usize, Gallery, Gallery.setRadio, 1) },
        .{ .label = "Pickup", .selected = state.radio == 2, .on_click = cx.listenerWith(usize, Gallery, Gallery.setRadio, 2) },
    };

    var avatars_row = rowOf(&.{
        Avatar.init("Edward T").size(.sm).render(),
        Avatar.init("Eddie Lake").size(.md).render(),
        Avatar.init("Jamik T").size(.lg).render(),
        Avatar.init("Mira K").size(.xl).render(),
        Avatar.init("Sam").shape(.square).size(.md).render(),
    }, 12);
    const avatar_stack = shadcn.AvatarGroup.init(&.{
        "Ann Chen", "Bob Iger", "Cid Vicious", "Dee Reynolds", "Mac P",
    }).render();
    avatars_row = avatars_row.child(avatar_stack);

    return pageColumn(&.{
        pageHeader("Inputs & controls", "Text, booleans, choices and a draggable slider.", body_width),
        sectionCard(state, "Text fields", "Presentation chrome; editable fields use zui's TextField entity.", zui.div().flex_row().flex_wrap().gap(32)
            .child(zui.div().flex_col().gap(12).w(320)
                .child(Input.init().placeholder("Email address").leadingIcon(.mail).render())
                .child(Input.init().placeholder("Search the docs").leadingIcon(.search).trailingIcon(.x).render())
                .child(Input.init().value("shadcn@example.com").leadingIcon(.mail).render())
                .child(Input.init().placeholder("Invalid value").invalid(true).render())
                .child(Input.init().value("Disabled").disabled(true).render()))
            .child(zui.div().flex_col().gap(12).w(320)
            .child(shadcn.Textarea.init().placeholder("Tell us a little bit about yourself").rows(4).render())
            .child(shadcn.Textarea.init().placeholder("Short description").rows(2).invalid(true).render()))),
        sectionCard(state, "Checkbox & switch", "Controlled booleans.", zui.div().flex_row().flex_wrap().gap(48)
            .child(zui.div().flex_col().gap(12)
                .child(rowWithControl(Checkbox.init().checked(state.checked[0]).render(), "Accept terms and conditions", cx.listenerWith(usize, Gallery, Gallery.flipChecked, 0)))
                .child(rowWithControl(Checkbox.init().checked(state.checked[1]).render(), "Send me product updates", cx.listenerWith(usize, Gallery, Gallery.flipChecked, 1)))
                .child(zui.div().flex_row().items_center().gap(10)
                    .child(Checkbox.init().checked(true).disabled(true).render())
                    .child(support.label("Disabled (checked)", 14, theme.muted_foreground)))
                .child(zui.div().flex_row().items_center().gap(10)
                .child(Checkbox.init().disabled(true).render())
                .child(support.label("Disabled", 14, theme.muted_foreground))))
            .child(zui.div().flex_col().gap(12)
            .child(rowWithControl(shadcn.Switch.init().checked(state.flags[0]).render(), "Airplane mode", cx.listenerWith(usize, Gallery, Gallery.flipFlag, 0)))
            .child(rowWithControl(shadcn.Switch.init().checked(state.flags[1]).render(), "Notifications", cx.listenerWith(usize, Gallery, Gallery.flipFlag, 1)))
            .child(rowWithControl(shadcn.Switch.init().checked(state.flags[2]).size(.sm).render(), "Compact mode", cx.listenerWith(usize, Gallery, Gallery.flipFlag, 2)))
            .child(zui.div().flex_row().items_center().gap(10)
            .child(shadcn.Switch.init().checked(true).disabled(true).render())
            .child(support.label("Disabled", 14, theme.muted_foreground))))),
        sectionCard(state, "Radio & rating", "Single choice from a list.", zui.div().flex_row().flex_wrap().gap(48)
            .child(shadcn.RadioGroup.init(radio_items[0..]).render())
            .child(zui.div().flex_col().gap(12)
            .child(zui.div().flex_row().items_center().gap(10)
            .child(shadcn.Rating.init(state.rating).onStars(state.rating_listeners[0..]).render())
            .child(support.label("Rate this release", 14, theme.muted_foreground))
            .child(Badge.init("rate me").variant(.secondary).size(.sm).render())))),
        sectionCard(state, "Slider", "Drag the thumb; the entity owns the value.", zui.div().flex_row().items_center().gap(16).w(400)
            .child(state.slider.toElement())
            .child(support.strong(state.slider_label, 14, theme.muted_foreground))),
        sectionCard(state, "Avatars", "Initials fallback, circle and square.", avatars_row),
    });
}

// ---------------------------------------------------------------------------
// Feedback
// ---------------------------------------------------------------------------

fn feedback(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    const spinners = rowOf(&.{
        state.spinner.render(),
        state.spinner_lg.render(),
        support.label("Spinner", 14, theme.muted_foreground),
    }, 16);

    const progress_column = zui.div().flex_col().gap(12).w(360)
        .child(shadcn.Progress.init(0.25).width(360).render())
        .child(shadcn.Progress.init(0.62).width(360).render())
        .child(shadcn.Progress.init(1).width(360).render());

    const skeletons = rowOf(&.{
        shadcn.Skeleton.init().circle().height(32).render(),
        zui.div().flex_col().gap(8)
            .child(shadcn.Skeleton.init().width(220).height(12).render())
            .child(shadcn.Skeleton.init().width(180).height(12).render())
            .child(shadcn.Skeleton.init().width(200).height(12).render()),
    }, 16);

    const alerts = zui.div().flex_col().gap(12).w(440)
        .child(shadcn.Alert.init("Heads up!").description("You can add components to your app using the cli.").render())
        .child(shadcn.Alert.init("Delete project").description("This action cannot be undone.").variant(.destructive).render())
        .child(shadcn.Alert.init("Deployed").description("Build 421 is live.").variant(.success).render());

    const toast_card = shadcn.Toast.init("Changes saved")
        .description("Your document was updated.")
        .variant(.success)
        .onDismiss(cx.listener(Gallery, Gallery.noop))
        .render();

    const toast_trigger = Button.init("Show toast").variant(.outline).size(.sm)
        .onClick(cx.listener(Gallery, Gallery.showToast)).render();

    const empty_state = shadcn.Empty.init("No projects yet")
        .description("Create your first project to get started.")
        .icon(.folder)
        .action(Button.init("Create project").variant(.primary).size(.sm).render())
        .height(220)
        .render();

    return pageColumn(&.{
        pageHeader("Feedback", "Status, loading and callouts.", body_width),
        sectionCard(state, "Spinner & progress", "Rotating loader and determinate bars.", zui.div().flex_row().flex_wrap().gap(48)
            .child(spinners)
            .child(progress_column)),
        sectionCard(state, "Skeletons", "Static placeholder blocks; apps drive the pulse.", skeletons),
        sectionCard(state, "Alerts", "Callout variants.", alerts),
        sectionCard(state, "Toast", "The card; apps stack them at the app root.", zui.div().flex_row().items_center().gap(16)
            .child(toast_card)
            .child(toast_trigger)),
        sectionCard(state, "Empty state", "Dashed callout for empty lists.", empty_state),
    });
}

// ---------------------------------------------------------------------------
// Overlays (the overlays themselves render at the app root)
// ---------------------------------------------------------------------------

fn overlays(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    return pageColumn(&.{
        pageHeader("Overlays", "Modals, sheets and floating panels. They render through the app root (paint order is z order).", body_width),
        Card.init()
            .title("Dialog & alert dialog")
            .description("Modal panels with a scrim; clicking the scrim dismisses.")
            .content(rowOf(&.{
                Button.init("Open dialog").variant(.outline).onClick(cx.listener(Gallery, Gallery.openDialog)).render(),
                Button.init("Open alert dialog").variant(.destructive).onClick(cx.listener(Gallery, Gallery.openAlert)).render(),
            }, 8))
            .render(),
        Card.init()
            .title("Sheet")
            .description("A side panel with its own scrim.")
            .content(zui.div().flex_row().gap(8)
                .child(Button.init("Open right sheet").variant(.outline).onClick(cx.listener(Gallery, Gallery.openSheet)).render()))
            .render(),
        Card.init()
            .title("Popover & dropdown menu")
            .description("Anchored at the pointer; click outside to dismiss.")
            .content(rowOf(&.{
                Button.init("Show popover").variant(.outline).onClick(cx.listener(Gallery, Gallery.openPopover)).render(),
                Button.init("Open menu").variant(.outline).onClick(cx.listener(Gallery, Gallery.openMenu)).render(),
                shadcn.Badge.init(state.menu_result).variant(.secondary).render(),
            }, 8))
            .render(),
        Card.init()
            .title("Tooltip")
            .description("A hint bubble anchored at the pointer.")
            .content(rowOf(&.{
                Button.init(if (state.tip_open) "Hide tooltip" else "Show tooltip").variant(.outline).onClick(cx.listener(Gallery, Gallery.toggleTooltip)).render(),
                shadcn.Badge.init(if (state.tip_open) "visible" else "hidden").variant(.outline).render(),
            }, 8))
            .render(),
    });
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

fn data(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    // Sorting lives in the app: permute the row order by the sort key.
    var order: [DOCS.len]usize = undefined;
    for (0..DOCS.len) |index| order[index] = index;
    if (state.sort_col) |column_index| {
        var outer: usize = 0;
        while (outer < DOCS.len) : (outer += 1) {
            var inner: usize = 0;
            while (inner + 1 < DOCS.len) : (inner += 1) {
                const a = order[inner];
                const b = order[inner + 1];
                const key_a = docKey(main.DOCS[a], column_index);
                const key_b = docKey(main.DOCS[b], column_index);
                const swap = if (state.sort_order == .desc)
                    std.mem.order(u8, key_a, key_b) == .lt
                else
                    std.mem.order(u8, key_b, key_a) == .lt;
                if (swap) {
                    order[inner] = b;
                    order[inner + 1] = a;
                }
            }
        }
    }

    const columns = [_]shadcn.DataTableColumn{
        .{ .title = "Header", .grow = true, .sort_state = sortStateFor(state, 0), .on_sort = cx.listenerWith(usize, Gallery, Gallery.toggleSort, 0) },
        .{ .title = "Section Type", .width = 150, .sort_state = sortStateFor(state, 1), .on_sort = cx.listenerWith(usize, Gallery, Gallery.toggleSort, 1) },
        .{ .title = "Status", .width = 130, .sort_state = sortStateFor(state, 2), .on_sort = cx.listenerWith(usize, Gallery, Gallery.toggleSort, 2) },
        .{ .title = "Reviewer", .width = 170, .sort_state = sortStateFor(state, 3), .on_sort = cx.listenerWith(usize, Gallery, Gallery.toggleSort, 3) },
    };

    var cells_store: [DOCS.len][4]zui.Element = undefined;
    var rows_store: [DOCS.len]shadcn.TableRow = undefined;
    for (order, 0..) |doc_index, slot| {
        const doc = main.DOCS[doc_index];
        cells_store[slot] = .{
            zui.div().flex_row().items_center().gap(8)
                .child(support.strong(doc.header, 14, theme.foreground))
                .child(icon.render(.file_text, 14, theme.muted_foreground)),
            Badge.init(doc.section).variant(.outline).render(),
            Badge.init(doc.status).variant(if (doc.done) .secondary else .primary).icon(if (doc.done) .circle_check else .loader).render(),
            support.label(doc.reviewer, 14, theme.body),
        };
        rows_store[slot] = .{
            .cells = &cells_store[slot],
            .selected = state.rows_checked[doc_index],
            .selection = cx.listenerWith(usize, Gallery, Gallery.toggleRowChecked, doc_index),
            .on_click = cx.listenerWith(usize, Gallery, Gallery.toggleRowChecked, doc_index),
        };
    }
    const table = shadcn.DataTable.init(columns[0..]).rows(rows_store[0..]).render();

    // Pagination: window around the current page; labels formatted into
    // per-slot state buffers (text is borrowed until paint).
    const page_window = shadcn.pagination.pageItems(state.page_num, 20);
    var page_items_buf: [9]shadcn.PaginationItem = undefined;
    var page_count: usize = 0;
    page_count = appendPageItem(&page_items_buf, page_count, .{ .kind = .prev, .on_click = cx.listener(Gallery, Gallery.prevPageNum) });
    var label_index: usize = 0;
    for (page_window.slots[0..page_window.len]) |slot| {
        if (slot.page) |number| {
            const label = std.fmt.bufPrint(&state.page_labels[label_index], "{d}", .{number}) catch "";
            label_index += 1;
            page_count = appendPageItem(&page_items_buf, page_count, .{
                .label = label,
                .current = number == state.page_num,
                .on_click = cx.listenerWith(usize, Gallery, Gallery.setPageNum, number),
            });
        } else {
            page_count = appendPageItem(&page_items_buf, page_count, .{ .kind = .ellipsis });
        }
    }
    page_count = appendPageItem(&page_items_buf, page_count, .{ .kind = .next, .on_click = cx.listener(Gallery, Gallery.nextPageNum) });
    const pagination = shadcn.Pagination.init(page_items_buf[0..page_count]).render();

    const breadcrumb_items: [3]shadcn.BreadcrumbItem = .{
        .{ .label = "Gallery", .icon = .house, .on_click = cx.listenerWith(Page, Gallery, Gallery.navTo, .overview) },
        .{ .label = "Components", .on_click = cx.listenerWith(Page, Gallery, Gallery.navTo, .buttons) },
        .{ .label = "Data", .current = true },
    };
    const breadcrumbs = shadcn.Breadcrumb.init(breadcrumb_items[0..]).render();

    const stepper_items: [3]shadcn.StepperItem = .{
        .{ .title = "Draft", .state = .complete, .label = "1" },
        .{ .title = "Review", .description = "Two reviewers assigned", .state = .current, .label = "2" },
        .{ .title = "Publish", .state = .incomplete, .label = "3" },
    };

    const description_items: [3]shadcn.DescriptionItem = .{
        .{ .term = "Status", .description = "Approved for review" },
        .{ .term = "Owner", .description = "Eddie Lake" },
        .{ .term = "Due", .description = "September 18" },
    };

    return pageColumn(&.{
        pageHeader("Data & tables", "Sortable tables, pagination and metadata rows.", body_width),
        sectionCard(state, "Data table", "Click a header to sort; checkbox column from the plain table.", zui.div().flex_col().gap(16)
            .child(breadcrumbs)
            .child(table)
            .child(zui.div().flex_row().items_center().justify_between()
            .child(support.label("Page", 13, theme.muted_foreground))
            .child(pagination))),
        sectionCard(state, "Stepper", "Horizontal step indicator.", shadcn.Stepper.init(stepper_items[0..]).render()),
        sectionCard(state, "Description list", "Term/value rows.", shadcn.DescriptionList.init(description_items[0..]).render()),
    });
}

fn sortStateFor(state: *Gallery, column_index: usize) shadcn.DataTableSort {
    if (state.sort_col != column_index) return .none;
    return state.sort_order;
}

fn docKey(doc: main.Doc, column_index: usize) []const u8 {
    return switch (column_index) {
        0 => doc.header,
        1 => doc.section,
        2 => doc.status,
        3 => doc.reviewer,
        else => "",
    };
}

fn appendPageItem(buf: []shadcn.PaginationItem, count: usize, item: shadcn.PaginationItem) usize {
    buf[count] = item;
    return count + 1;
}

// ---------------------------------------------------------------------------
// Extras: batch A-E components
// ---------------------------------------------------------------------------

fn extras(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    const TimeField = shadcn.TimeField;

    // Statistic row.
    const stats = rowOf(&.{
        shadcn.Statistic.init("1,250.00").label("Total revenue").delta("+12.5%", .up).sub("vs last month").render(),
        shadcn.Statistic.init("45,678").label("Active accounts").delta("-4.2%", .down).render(),
        shadcn.Statistic.init("98.2%").label("Uptime").render(),
    }, 48);

    // Results.
    const result_ok = shadcn.Result.init("All checks passed")
        .status(.success)
        .description("Your component wave is complete.")
        .actions(Button.init("Done").variant(.primary).size(.sm).render())
        .render();
    const result_err = shadcn.Result.init("Build failed")
        .status(.err)
        .description("2 tests failed in the last run.")
        .actions(Button.init("Retry").variant(.outline).size(.sm).render())
        .render();

    // Tags.
    const tags = rowOf(&.{
        shadcn.Tag.init("design").render(),
        shadcn.Tag.init("breaking").variant(.destructive).render(),
        shadcn.Tag.init("zui").variant(.primary)
            .onRemove(cx.listener(Gallery, Gallery.noop)).render(),
    }, 8);

    // Items.
    const items = zui.div().flex_col().gap(8).w(420)
        .child(shadcn.Item.init("Add to workspace")
            .description("Everything new lands here first.")
            .media(icon.render(semantic.folder, 18, theme.muted_foreground))
            .actions(Button.init("Open").variant(.outline).size(.sm).render()).render())
        .child(shadcn.Item.init("Indicator dot")
        .description("Badges layered over content.")
        .media(shadcn.Indicator.init(shadcn.Avatar.init("EK").size(.sm).render()).asDot().render())
        .render());

    // Timeline.
    const timeline_items = [_]shadcn.timeline.Item{
        .{ .title = "Wave 1", .description = "Display components", .state_kind = .complete, .time_text = "Sep 16" },
        .{ .title = "Wave 2", .description = "Menus and pickers", .state_kind = .complete },
        .{ .title = "Charts", .description = "Twelve new SVG types", .state_kind = .current },
        .{ .title = "Docs", .state_kind = .pending },
    };
    const timeline = shadcn.Timeline.init(timeline_items[0..]).render();

    // Attachments.
    const attachments = rowOf(&.{
        shadcn.Attachment.init("cover-page.pdf").sizeText("1.2 MB").render(),
        shadcn.Attachment.init("screenshot.png").sizeText("340 KB")
            .onRemove(cx.listener(Gallery, Gallery.noop)).render(),
        shadcn.Attachment.init("notes.txt").render(),
    }, 12);

    // Comments.
    const comment = shadcn.Comment.init("Eddie Lake").avatar("Eddie Lake").at("2h ago")
        .content(zui.div().child(support.label("The slider drag check passes at 71 after the +100px drag.", 14, theme.body)))
        .actions(zui.div().flex_row().gap(12)
            .child(shadcn.Link.init("Reply").render())
            .child(shadcn.Link.init("Resolve").render()))
        .render();

    // List.
    var list_items: [3]shadcn.ListItem = .{
        .{ .label = "Linear", .description = "Issues", .icon_name = semantic.square_mouse_pointer, .selected = true, .on_click = cx.listener(Gallery, Gallery.noop) },
        .{ .label = "Figma", .icon_name = semantic.square_mouse_pointer, .on_click = cx.listener(Gallery, Gallery.noop) },
        .{ .label = "Notion", .icon_name = semantic.square_mouse_pointer, .disabled = true },
    };

    // Segmented control.
    var segments: [3]shadcn.components.segmented.Option = .{
        .{ .label = "Day", .selected = state.segmented == 0, .on_click = cx.listenerWith(usize, Gallery, Gallery.setSegment, 0) },
        .{ .label = "Week", .selected = state.segmented == 1, .on_click = cx.listenerWith(usize, Gallery, Gallery.setSegment, 1) },
        .{ .label = "Month", .selected = state.segmented == 2, .on_click = cx.listenerWith(usize, Gallery, Gallery.setSegment, 2) },
    };
    _ = &segments;

    // Menubar + navigation menu.
    const menubar = shadcn.Menubar.init(&.{
        .{ .label = "File", .on_click = cx.listener(Gallery, Gallery.noop) },
        .{ .label = "Edit", .active = true, .on_click = cx.listener(Gallery, Gallery.noop) },
        .{ .label = "View", .on_click = cx.listener(Gallery, Gallery.noop) },
    }).render();
    const nav_menu = shadcn.NavigationMenu.init(&.{
        .{ .label = "Overview", .on_click = cx.listenerWith(Page, Gallery, Gallery.navTo, .overview) },
        .{ .label = "Charts", .active = true, .on_click = cx.listenerWith(Page, Gallery, Gallery.navTo, .charts) },
        .{ .label = "Data", .count_text = "4", .on_click = cx.listenerWith(Page, Gallery, Gallery.navTo, .data) },
    }).render();

    // Time field.
    const time_field = TimeField.init()
        .hour(hourText(state.time_hour))
        .minute(minuteText(state.time_minute))
        .onHourUp(cx.listener(Gallery, Gallery.hourUp))
        .onHourDown(cx.listener(Gallery, Gallery.hourDown))
        .onMinuteUp(cx.listener(Gallery, Gallery.minuteUp))
        .onMinuteDown(cx.listener(Gallery, Gallery.minuteDown))
        .render();

    // TextView blocks.
    var blocks = [_]shadcn.TextViewBlock{
        .{ .heading = .{ .level = 2, .text = "How overlays work" } },
        .{ .paragraph = "They render as the last children of the app root: later siblings paint on top." },
        .{ .bullet = "Dialogs and sheets take a scrim" },
        .{ .bullet = "Popovers and menus anchor at the pointer" },
        .{ .code = "root = root.child(shadcn.Dialog.init().render());" },
    };
    _ = &blocks;
    const text_view = shadcn.TextView.init(blocks[0..]).render();

    // Questionnaire (static step).
    const questionnaire = shadcn.Questionnaire.init("Workspace details", zui.div().flex_col().gap(8).w(320)
        .child(shadcn.Field.init("Team name").control(Input.init().placeholder("Acme Inc.").render()).render())
        .child(shadcn.Field.init("Subdomain")
        .control(Input.init().value("acme").leadingIcon(.terminal).render()).render()))
        .description("Two more steps and you are done.")
        .step(2, 4)
        .onBack(cx.listener(Gallery, Gallery.noop))
        .onNext(cx.listener(Gallery, Gallery.noop))
        .render();

    // Aspect ratio.
    const aspect = shadcn.AspectRatio.init(16.0 / 9.0).width(360)
        .content(zui.div().size_full().flex_row().items_center().justify_center()
            .rounded_lg().bg(theme.secondary)
            .child(support.label("16:9", 14, theme.muted_foreground)))
        .render();

    return pageColumn(&.{
        pageHeader("Extras", "The second wave: display, menus, structure and pickers.", body_width),
        sectionCard(state, "Statistics", "Big numbers with deltas.", stats),
        sectionCard(state, "Results", "Status pages with actions.", zui.div().flex_col().gap(16)
            .child(result_ok).child(result_err)),
        sectionCard(state, "Tags & attachments", "Closable chips and file chips.", zui.div().flex_col().gap(12)
            .child(tags).child(attachments)),
        sectionCard(state, "Items & indicators", "Media rows with layered badges.", items),
        sectionCard(state, "Timeline", "Vertical step history.", timeline),
        sectionCard(state, "Comment & list", "Discussion row and a selectable list.", zui.div().flex_row().flex_wrap().gap(32)
            .child(zui.div().w(360).child(comment))
            .child(shadcn.List.init(list_items[0..]).render())),
        sectionCard(state, "Segmented, FAB & dropdown button", "More button shapes.", zui.div().flex_row().flex_wrap().items_center().gap(16)
            .child(shadcn.Segmented.init(segments[0..]).render())
            .child(shadcn.Fab.init(semantic.plus).onClick(cx.listener(Gallery, Gallery.noop)).render())
            .child(shadcn.DropdownButton.init("Actions").onOpen(cx.listener(Gallery, Gallery.openMenu)).render())),
        sectionCard(state, "Menubar & navigation menu", "Horizontal menu surfaces.", zui.div().flex_col().gap(12)
            .child(menubar).child(nav_menu)),
        sectionCard(state, "Calendar", "Month grid and range picker; the entity owns state.", zui.div().flex_row().flex_wrap().items_center().gap(24)
            .child(state.calendar.toElement())
            .child(zui.div().flex_col().gap(16).child(state.range_calendar.toElement()).child(time_field))),
        sectionCard(state, "Text view", "Block-level markdown subset.", text_view),
        sectionCard(state, "Questionnaire", "Paged form flow.", questionnaire),
        sectionCard(state, "Aspect ratio", "Ratio-constrained frame.", aspect),
    });
}

var time_buf: [8]u8 = undefined;
var time_buf2: [8]u8 = undefined;

fn hourText(value: u32) []const u8 {
    return std.fmt.bufPrint(&time_buf, "{d:0>2}", .{value}) catch "";
}

fn minuteText(value: u32) []const u8 {
    return std.fmt.bufPrint(&time_buf2, "{d:0>2}", .{value}) catch "";
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

fn charts(state: *Gallery, body_width: f32) zui.Element {
    const area_series = [_]shadcn.ChartSeries{
        .{ .values = &main.VISITORS, .stroke = theme.foreground, .fill_top = theme.muted_foreground, .fill_bottom = theme.background },
        .{ .values = &main.MOBILE, .stroke = theme.foreground, .fill_top = theme.faint, .fill_bottom = theme.secondary },
    };
    const area = AreaChart.init(area_series[0..]).size(body_width - 48, 240).gridStep(250);

    const bar_groups = [_]shadcn.BarChartGroup{
        .{ .label = "Jan", .values = &.{ 120, 40 } },
        .{ .label = "Feb", .values = &.{ 80, 160 } },
        .{ .label = "Mar", .values = &.{ 150, 90 } },
        .{ .label = "Apr", .values = &.{ 60, 130 } },
        .{ .label = "May", .values = &.{ 110, 70 } },
        .{ .label = "Jun", .values = &.{ 170, 120 } },
    };
    const bar_palette = [_]zui.Color{ theme.chart_1, theme.chart_3 };
    const bar = shadcn.BarChart.init(bar_groups[0..]).paletteFor(bar_palette[0..]).size(body_width - 48, 220).gridStep(50);

    const line_set = [_]shadcn.ChartLine{
        .{ .values = &main.LINE_A, .stroke = theme.chart_2, .dots = true },
        .{ .values = &main.LINE_B, .stroke = theme.faint, .dots = true },
    };
    const line = shadcn.LineChart.init(line_set[0..]).size(body_width - 48, 220).gridStep(50);

    const pie_slices = [_]shadcn.PieSlice{
        .{ .value = 6, .fill = theme.chart_1 },
        .{ .value = 2, .fill = theme.chart_2 },
        .{ .value = 1, .fill = theme.chart_3 },
        .{ .value = 1, .fill = theme.faint },
    };
    const donut = shadcn.PieChart.init(pie_slices[0..]).size(200).innerRadius(60);

    const donut_legend = zui.div().flex_col().gap(8)
        .child(legendDot(theme.chart_1, "Desktop · 60%"))
        .child(legendDot(theme.chart_2, "Mobile · 20%"))
        .child(legendDot(theme.chart_3, "Tablet · 10%"))
        .child(legendDot(theme.faint, "Other · 10%"));

    // -- second-wave charts (pure SVG builders) --
    const scatter_points = [_]shadcn.components.chart.scatter.Point{
        .{ .x = 1, .y = 3, .weight = 0.2 },
        .{ .x = 2, .y = 7, .weight = 0.6 },
        .{ .x = 3.5, .y = 5, .weight = 0.4 },
        .{ .x = 4, .y = 9, .weight = 0.9 },
        .{ .x = 5, .y = 6, .weight = 0.3 },
        .{ .x = 6.2, .y = 8, .weight = 0.7 },
    };
    const scatter = shadcn.ScatterChart.init(scatter_points[0..]).size(body_width / 2 - 24, 220);
    const bubble = scatter_chart_bubble(scatter_points[0..]);

    const radar_series = [_][]const f32{ &main.RADAR_A, &main.RADAR_B };
    const radar_palette = [_]zui.Color{ theme.chart_1, theme.chart_3 };
    const radar = shadcn.RadarChart.init(radar_series[0..]).size(240).paletteFor(radar_palette[0..]);

    const gauge = shadcn.GaugeChart.init(0.72).size(160);
    const spark = shadcn.Sparkline.init(&main.SPK).color(theme.chart_2).size(220, 40);

    const heat_values = [_]f32{ 2, 4, 6, 1, 0, 3, 5, 5, 8, 3, 2, 4, 6, 7, 2, 1, 4, 6, 8, 9, 5, 4, 3, 2 };
    const heat = shadcn.Heatmap.init(heat_values[0..], 4, 6).size(300, 180);

    const tree_values = [_]shadcn.components.chart.treemap.Node{
        .{ .label = "Desktop", .value = 6 },
        .{ .label = "Mobile", .value = 3 },
        .{ .label = "Tablet", .value = 2 },
        .{ .label = "Other", .value = 1 },
    };
    const treemap = shadcn.Treemap.init(tree_values[0..]).size(300, 180);

    const funnel_values = [_]f32{ 620, 410, 220, 90 };
    const funnel = shadcn.FunnelChart.init(funnel_values[0..]).size(300, 220);

    const candles = [_]shadcn.Candle{
        .{ .open = 40, .high = 48, .low = 38, .close = 46 },
        .{ .open = 46, .high = 52, .low = 44, .close = 42 },
        .{ .open = 42, .high = 50, .low = 41, .close = 49 },
        .{ .open = 49, .high = 55, .low = 47, .close = 51 },
        .{ .open = 51, .high = 53, .low = 44, .close = 45 },
        .{ .open = 45, .high = 52, .low = 45, .close = 50 },
    };
    const candle = shadcn.Candlestick.init(candles[0..]).size(420, 200);

    const box_outliers = [_]f32{92};
    const boxes = [_]shadcn.Box{
        .{ .min = 18, .q1 = 32, .median = 45, .q3 = 58, .max = 78 },
        .{ .min = 25, .q1 = 40, .median = 52, .q3 = 64, .max = 84, .outliers = box_outliers[0..] },
        .{ .min = 12, .q1 = 28, .median = 36, .q3 = 50, .max = 70 },
        .{ .min = 30, .q1 = 44, .median = 55, .q3 = 68, .max = 88 },
    };
    const boxplot = shadcn.BoxPlot.init(boxes[0..]).size(420, 200);

    const waterfall_deltas = [_]f32{ 120, -40, 60, -25, 80 };
    const waterfall = shadcn.WaterfallChart.init(waterfall_deltas[0..]).size(420, 200);

    var stacked_area_series = [_][]const f32{ &main.MOBILE, &main.LINE_B, &main.LINE_A };
    _ = &stacked_area_series;
    const stacked_area = shadcn.StackedAreaChart.init(stacked_area_series[0..]).size(body_width - 48, 220);

    var stacked_bar_groups = [_][]const f32{
        &.{ 40, 20 },
        &.{ 62, 35 },
        &.{ 55, 25 },
        &.{ 30, 45 },
        &.{ 70, 30 },
        &.{ 65, 40 },
    };
    _ = &stacked_bar_groups;
    const stacked_bar = shadcn.StackedBarChart.init(stacked_bar_groups[0..]).size(body_width - 48, 220);

    const hbar_values = [_]f32{ 62, 41, 88, 30, 55 };
    const hbar = shadcn.HBarChart.init(hbar_values[0..]).size(360, 180);

    const composed_bars = [_]f32{ 40, 62, 55, 78, 66, 84 };
    const composed_line = [_]f32{ 30, 44, 60, 52, 70, 90 };
    const composed = shadcn.ComposedChart.init(composed_bars[0..], composed_line[0..])
        .size(body_width - 48, 220);

    return pageColumn(&.{
        pageHeader("Charts", "SVG-generated: splines, bars, lines and donut wedges.", body_width),
        sectionCard(state, "Area chart", "Stacked natural-spline areas.", zui.div().flex_col().gap(12)
            .child(area.render(&state.area_buf))
            .child(zui.div().flex_row().items_center().gap(16)
            .child(legendDot(theme.muted_foreground, "Desktop"))
            .child(legendDot(theme.faint, "Mobile")))),
        sectionCard(state, "Stacked area", "Layered bands bottom-up.", stacked_area.render(&state.stacked_area_buf)),
        sectionCard(state, "Bar chart", "Grouped bars per month.", zui.div().flex_col().gap(12)
            .child(bar.render(&state.bar_buf))
            .child(zui.div().flex_row().gap(16)
            .child(legendDot(theme.chart_1, "Direct"))
            .child(legendDot(theme.chart_3, "Referral")))),
        sectionCard(state, "Stacked bar", "Layered bars per month.", stacked_bar.render(&state.stacked_bar_buf)),
        sectionCard(state, "Horizontal bars", "Row-oriented bars.", hbar.render(&state.hbar_buf)),
        sectionCard(state, "Line chart", "Two series with point dots.", line.render(&state.line_buf)),
        sectionCard(state, "Composed", "Bars + a line on one domain.", composed.render(&state.composed_buf)),
        sectionCard(state, "Donut", "Ring wedges with a legend.", zui.div().flex_row().items_center().gap(32)
            .child(donut.render(&state.pie_buf))
            .child(donut_legend)),
        sectionCard(state, "Scatter & bubble", "Points; bubble mode sizes by weight.", zui.div().flex_row().flex_wrap().gap(24)
            .child(scatter.render(&state.scatter_buf))
            .child(bubble.render(&state.scatter_bubble_buf))),
        sectionCard(state, "Radar & gauge", "Polar polygons and a 270-degree gauge.", zui.div().flex_row().flex_wrap().items_center().gap(24)
            .child(radar.render(&state.radar_buf))
            .child(gauge.render(&state.gauge_buf))
            .child(zui.div().flex_col().gap(8).child(spark.render(&state.spark_buf)))),
        sectionCard(state, "Candlestick & waterfall", "OHLC candles and running totals.", zui.div().flex_row().flex_wrap().gap(24)
            .child(candle.render(&state.candle_buf))
            .child(waterfall.render(&state.waterfall_buf))),
        sectionCard(state, "Box plot", "Five-number summaries with whiskers and outliers.", boxplot.render(&state.boxplot_buf)),
        sectionCard(state, "Heatmap & treemap & funnel", "Value grids and proportional shapes.", zui.div().flex_row().flex_wrap().gap(24)
            .child(heat.render(&state.heatmap_buf))
            .child(treemap.render(&state.treemap_buf))
            .child(funnel.render(&state.funnel_buf))),
    });
}

fn scatter_chart_bubble(points: []const shadcn.components.chart.scatter.Point) shadcn.ScatterChart {
    return shadcn.ScatterChart.init(points).size(240, 220).bubble();
}

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------

fn navigation(state: *Gallery, body_width: f32, cx: *zui.Context(Gallery)) zui.Element {
    var tab_items: [3]shadcn.TabItem = .{
        .{ .label = "Outline", .active = state.tab == 0, .on_click = cx.listenerWith(usize, Gallery, Gallery.setTab, 0) },
        .{ .label = "Past Performance", .active = state.tab == 1, .count = "2", .on_click = cx.listenerWith(usize, Gallery, Gallery.setTab, 1) },
        .{ .label = "Key Personnel", .active = state.tab == 2, .count = "3", .on_click = cx.listenerWith(usize, Gallery, Gallery.setTab, 2) },
    };
    const tabs = Tabs.init(tab_items[0..]).render();

    var accordion_items: [3]shadcn.AccordionItem = .{
        .{ .title = "What is shadcn-zui?", .open = state.accordion_open[0], .on_click = cx.listenerWith(usize, Gallery, Gallery.flipAccordion, 0), .content_value = zui.div().child(support.label("A component library for zui styled after shadcn/ui, laid out like gpui-kit.", 14, theme.body)) },
        .{ .title = "How are icons bundled?", .open = state.accordion_open[1], .on_click = cx.listenerWith(usize, Gallery, Gallery.flipAccordion, 1), .content_value = zui.div().child(support.label("1830 Lucide icons ship in the asset folder; IconName is generated by tools/gen_icons.py.", 14, theme.body)) },
        .{ .title = "How do overlays work?", .open = state.accordion_open[2], .on_click = cx.listenerWith(usize, Gallery, Gallery.flipAccordion, 2), .content_value = zui.div().child(support.label("They render as the last children of the app root: zui paints siblings in order, so later children cover earlier ones.", 14, theme.body)) },
    };

    var command_items: [4]shadcn.CommandItem = .{
        .{ .label = "Toggle theme", .icon = .palette, .shortcut = "⌘T", .selected = state.command_hover == 0 },
        .{ .label = "Open settings", .icon = .settings, .shortcut = "⌘,", .selected = state.command_hover == 1 },
        .{ .kind = .separator },
        .{ .label = "Search documents", .icon = .search, .selected = state.command_hover == 2 },
    };

    var scroll_items = zui.div().flex_col().gap(8);
    for (0..12) |_| {
        scroll_items = scroll_items.child(zui.div().flex_row().items_center().gap(8).h(22)
            .child(support.label("Scrollable row item", 14, theme.body))
            .child(zui.spacer())
            .child(support.label("row", 12, theme.faint)));
    }

    const collapsible = shadcn.Collapsible.init()
        .open(state.collapse_open)
        .trigger(zui.div().flex_row().gap(8)
            .child(Button.init(if (state.collapse_open) "Hide details" else "Show details").variant(.outline).size(.sm).trailingIcon(.chevron_down).onClick(cx.listener(Gallery, Gallery.flipCollapse)).render()))
        .content(zui.div().flex_col().gap(8)
            .child(support.label("· Overlays render through the app root (paint order = z order).", 14, theme.body))
            .child(support.label("· Text slices are borrowed until paint.", 14, theme.body))
            .child(support.label("· No allocation in render: buffers live in app state.", 14, theme.body)))
        .render();

    const scroll_area = shadcn.ScrollArea.init(state.scroll_area_offset).height(220).border(true)
        .content(scroll_items)
        .onScroll(cx.listener(Gallery, Gallery.onAreaScroll))
        .render();

    return pageColumn(&.{
        pageHeader("Navigation", "Tabs, disclosure, palettes and scroll.", body_width),
        sectionCard(state, "Tabs", "Segmented filters with counts.", rowOf(&.{tabs}, 0)),
        sectionCard(state, "Accordion & collapsible", "Expandable sections.", zui.div().flex_col().gap(16)
            .child(shadcn.Accordion.init(accordion_items[0..]).render())
            .child(collapsible)),
        sectionCard(state, "Command palette", "Usually hosted in a popover overlay.", shadcn.Command.init(command_items[0..]).render()),
        sectionCard(state, "Group box & links", "Titled sections, key hints and inline links.", zui.div().flex_row().flex_wrap().items_center().gap(24)
            .child(shadcn.GroupBox.init("Keyboard shortcuts").content(zui.div().flex_row().items_center().gap(8)
                .child(shadcn.Kbd.init("⌘ T").render())
                .child(shadcn.Kbd.init("⌘ ,").render())
                .child(support.label("to open the palette", 13, theme.muted_foreground))).render())
            .child(shadcn.Link.init("Documentation").icon(.book_open).onClick(cx.listener(Gallery, Gallery.showToast)).render())
            .child(shadcn.Link.init("View source").icon(.external_link).render())),
        sectionCard(state, "Scroll area", "Wheel-driven viewport; the offset lives in app state.", scroll_area),
    });
}
