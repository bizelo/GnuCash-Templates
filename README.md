# Sleek Modern Invoice (GNUCash)

A modern, CSS-driven invoice stylesheet for **GNUCash**, designed to significantly improve the default invoice appearance while remaining fully compatible with GNUCash’s built-in reporting system.

This stylesheet focuses on:
- A clean, card-based layout
- Subtle gradients and visual hierarchy
- A customizable accent color
- Optional company logo support
- No HTML template changes required (CSS + Scheme only)

---

## Features

- Modern visual design with rounded cards and soft shadows
- Accent color selection using GNUCash’s native color picker
- Logo upload support (PNG, SVG, JPG)
- Compatible with existing GNUCash invoice data
- CSS-only rendering (no custom HTML templates)

---

## Tested Environment

This stylesheet has been **tested and confirmed working** on:

- GNUCash **5.14**
- **macOS**

It has **not yet been tested** on:
- Other GNUCash versions
- Linux or Windows builds

GNUCash’s stylesheet option system can behave differently across versions and platforms. Issues on other setups are possible.

---

## Files in This Repository

- `config-user.scm`  
  Registers the *Sleek Modern Invoice* stylesheet and exposes user options (accent color, logo).

- `sleek-modern-invoice.css`  
  The full CSS theme used by the invoice.

---

## Installation (All Platforms)

GNUCash loads user configuration files from the directory specified by the
`GNC_CONFIG_HOME` environment variable.

If `GNC_CONFIG_HOME` is **not set**, GNUCash defaults to a platform-specific
configuration directory, commonly:

- **Linux / BSD**: `~/.config/gnucash`
- **macOS**: `~/Library/Application Support/Gnucash`
- **Windows**: `%APPDATA%\GnuCash`

You can confirm the active configuration directory by checking the
`GNC_CONFIG_HOME` environment variable or GNUCash documentation for your platform.

---

### 1. Install the Scheme file

Copy `config-user.scm` into:

```
$GNC_CONFIG_HOME/config-user.scm
```

If a `config-user.scm` file already exists, merge the contents carefully.

---

### 2. Install the CSS file

Copy `sleek-modern-invoice.css` into:

```
$GNC_CONFIG_HOME/sleek-modern-invoice.css
```

---

### 3. Restart GNUCash

GNUCash must be fully restarted for new stylesheets to load.

---

## Using the Invoice Style

### Select the stylesheet
1. Open GNUCash
2. Go to **Edit → Style Sheets**
3. Select **Sleek Modern Invoice**
4. Click **Options** to customize

### Available options
- **Accent Color**  
  Uses GNUCash’s native color picker.

- **Logo Image**  
  Upload a company logo (PNG, SVG, or JPG recommended).

---

### Apply to an invoice
1. Open an invoice
2. Choose **Print Invoice**
3. Click **Options**
4. Under **General → Stylesheet**, select **Sleek Modern Invoice**
5. Preview or export to PDF

---

## Notes and Limitations

- This theme relies on GNUCash’s embedded HTML renderer, which may not support all modern CSS features.
- The stylesheet avoids unsupported features such as `color-mix()` to maintain compatibility.
- Layout is tuned for standard invoice formats and may require adjustments for heavily customized invoices.

---

## License

MIT License

---

## Credits

Created as a custom invoice theme inspired by modern SaaS design aesthetics and refined through hands-on testing with GNUCash 5.14 on macOS.

---

## Feedback and Contributions

Issues, improvements, and pull requests are welcome.  
If you test this on other platforms or GNUCash versions, please share your results.
