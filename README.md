# zig_timer

## Usage

```
zig build
```

```
./zig-out/bin/zig_timer 30s
```

Enable desktop notifications (macOS via `osascript`, Linux/BSD via `notify-send`) in addition to the terminal bell:

```
./zig-out/bin/zig_timer --notify 1m30s
```
