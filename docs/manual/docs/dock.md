# Side Bar Concepts and Usage

## Side Bar Overview

The **Side Bar**, items 4 and 6 in the main window guide provides an area for optional widgets.

![main](images/main-window.png){: width="100%" }

A very simple, bespoke panel comprising embedded resizeable panes has been implemented.

* The panel consists for four vertical panels
* The top panel can hold three horizontal panes
* The other panels can hold two horizontal panes.

Each pane has a divider line between it and adjacent panels. **The size of individual panes may be adjusted by moving the dividers.** mwp will remember the relative sizing of the panels.

The main sidebar (dock) controls are shown below. Please note some of these images are from the legacy version of {{ mwp }}.:

## Side Bar Items (Dockets)

The following items are provided.

### Artificial Horizon

![dockah](images/dock_ah.png){: width="30%" }

### Direction View

![dockdir](images/dock_dirn.png){: width="15%" }

### Flight View

![dockdir](images/dock_fv.png){: width="33%" }

### RSSI / LQ Status

![dockdir](images/dock_radio.png){: width="15%" }

### Battery Monitor

![dockdir](images/dock_batt.png){: width="30%" }

### Vario View

![dockdir](images/dock_vario.png){: width="25%" }
![dockdir](images/dock_vario_l.png){: width="25%" }
![dockdir](images/dock_vario_d.png){: width="25%" }

### Wind Estimator (new / Gtk4)

![dockwind](images/panel-vas.png){: width="25%" }

## Side Bar Configuration

The configuration may be user defined by a simple text file `~/.config/mwp/panel.conf`.

Each entry is defined by a comma separated line defining the panel widget name, the row (0-3) and the column (0-2) and an optional minimum size (only required for the artificial horizon).

The default panel is defined (in the absence of a configuration file) as:

```
# default widgets
ahi,0,1,100
rssi, 1, 0
dirn, 1, 1
flight, 2, 0
volts, 3, 0
```

Which appears as:
![mwp4-panel-0](images/mwp4-panel-0.png)

### In line editor

From 25.04.15, it is possible to edit the panel in-line. A popup menu is displayed on right mouse press on a panel pane. Note that in the default configuration, some of the pane dividers may be flush against an edge, and it will be necessary to drag the dividers to expose all the unused panels.

On a blank pane, the popup menu offers all non-deployed widgets. Here only "WindSpeed" is available to be added.

![mwp4-panel-e0](images/panel-edit-0.png)

The result after adding "WindSpeed":

![mwp4-panel-e1](images/panel-edit-1.png)

When the popup menu is invoked for a populated pane, only "Remove Item" is available.

[Video example](https://youtu.be/U7EpvuZLQ74) showing right mouse button menu usage.

<iframe width="827" height="594"
src="https://www.youtube.com/embed/U7EpvuZLQ74" title="mwp panel"
frameborder="0" allow="accelerometer; autoplay; clipboard-write;
encrypted-media; gyroscope; picture-in-picture; web-share"
referrerpolicy="strict-origin-when-cross-origin"
allowfullscreen></iframe>

### Available Widgets

The available panel widgets are named as:

| Name | Usage |
| ---- | ---- |
| `ahi` | Artificial horizon |
| `dirn` | Direction comparison |
| `flight` | "Flight View" Position / Velocity / Satellites etc, |
| `volts` | Battery information |
| `vario` | Vario indicator |
|  `wind` | Wind Estimator (BBL replay only) |

No other legacy widgets have been migrated.

So using the following `~/.config/mwp/panel.conf`

```
# default + vario + wind widgets
ahi, 0, 1, 100
vario,0,2
rssi, 0, 0
wind, 1, 0
dirn, 1, 1
flight, 2, 0
volts, 3, 0
```

would appear as:
![mwp4-panel-1](images/mwp4-panel-1.png)

Panel sizes have been adjusted to make best use of available space.
