---
name: Henshin
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#3e4949'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#6e7979'
  outline-variant: '#bdc9c8'
  surface-tint: '#006a6a'
  primary: '#006565'
  on-primary: '#ffffff'
  primary-container: '#008080'
  on-primary-container: '#e3fffe'
  inverse-primary: '#76d6d5'
  secondary: '#516161'
  on-secondary: '#ffffff'
  secondary-container: '#d4e6e5'
  on-secondary-container: '#576867'
  tertiary: '#8b4823'
  on-tertiary: '#ffffff'
  tertiary-container: '#a96039'
  on-tertiary-container: '#fff9f7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#93f2f2'
  primary-fixed-dim: '#76d6d5'
  on-primary-fixed: '#002020'
  on-primary-fixed-variant: '#004f4f'
  secondary-fixed: '#d4e6e5'
  secondary-fixed-dim: '#b8cac9'
  on-secondary-fixed: '#0e1e1e'
  on-secondary-fixed-variant: '#3a4a49'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb692'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#733512'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display-price:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 24px
  gutter: 16px
  touch-target-min: 48px
---

## Brand & Style

The design system is built on the principles of **Modern Minimalism** tailored for a high-traffic Point of Sale environment. The objective is to reduce cognitive load for staff and provide a sense of calm reliability for business owners. 

The aesthetic is characterized by expansive whitespace, a limited "high-key" color palette, and soft, organic shapes. By eliminating unnecessary borders and visual noise, the interface prioritizes speed and accuracy. The emotional response should be one of "effortless efficiency"—a tool that feels invisible until it is needed.

## Colors

The palette is intentionally restrained to ensure that the primary action color—a confident Teal—commands immediate attention. 

- **Primary (#008080):** Used exclusively for high-priority actions like "Bayar" (Pay), "Selesai" (Finish), and active states.
- **Secondary (#E0F2F1):** A soft tint used for subtle highlights, toggle backgrounds, or secondary buttons.
- **Neutral Surface (#F8FAFC):** The foundation of the UI. Use various shades of cool grays and off-whites to differentiate between the sidebar, product grid, and receipt preview.
- **Text:** High-contrast charcoal (#1E293B) for primary information and muted slate (#64748B) for metadata and labels.

## Typography

This design system utilizes **Inter** for its exceptional legibility at small sizes and its neutral, systematic character. 

- **Numerical Clarity:** Since this is a POS app, pricing uses `display-price` with tight letter spacing to ensure large totals are readable at a glance from a distance.
- **Hierarchy:** Use `headline-md` for product categories and `body-md` for item names.
- **Indonesian Context:** Ensure line heights are generous enough to accommodate the lack of descenders in many Indonesian words, maintaining a clean "airy" look between rows in the cart list.

## Layout & Spacing

The layout follows a **Fixed Grid** for tablet/desktop views to maintain a consistent dashboard feel, while transitioning to a **Fluid Grid** for mobile handheld terminals.

- **The 8px Rule:** All spacing between elements must be a multiple of 8px.
- **Product Grid:** Items are displayed in cards with 16px gutters. On tablets, use a 4 or 5 column grid. On mobile, use a 2 column grid.
- **Split Screen:** On large screens, the "Daftar Pesanan" (Order List) should be pinned to the right (fixed width 380px), while the product selection remains fluid on the left.
- **Safe Zones:** Maintain a 24px margin around the edges of the screen to prevent accidental touches near the bezel.

## Elevation & Depth

To maintain a minimalist look, this design system avoids heavy borders and instead uses **Tonal Layers** and **Ambient Shadows**.

- **Level 0 (Background):** #F8FAFC. Used for the main canvas.
- **Level 1 (Cards/Sidebar):** Pure white (#FFFFFF) with a very soft, diffused shadow (0px 4px 20px rgba(0, 0, 0, 0.04)). This makes product cards appear to lift slightly off the page.
- **Level 2 (Modals/Popovers):** Pure white with a more defined shadow (0px 10px 30px rgba(0, 0, 0, 0.08)) to indicate focus.
- **Interactions:** When a product card is tapped, it should briefly scale down (98%) rather than changing color, mimicking a physical press.

## Shapes

The shape language is defined by "Soft Logic." Surfaces are rounded to feel approachable and modern, but not so circular as to waste space.

- **Standard Components:** Buttons and Input fields use a 12px radius.
- **Containers:** Product cards and the main order list container use `rounded-lg` (16px).
- **Selection Indicators:** Use pill-shaped (100px) chips for categories to distinguish them from rectangular product cards.

## Components

### Buttons
- **Primary:** Background #008080, Text #FFFFFF. 12px radius. Min-height 56px for easy tapping in fast-paced environments.
- **Secondary:** Background #E0F2F1, Text #008080. Used for "Diskon" or "Catatan."

### Cards
- Product cards feature a top-aligned image (if available) with the price in `label-sm` bold at the bottom right. No border; use Level 1 Elevation.

### Order List (Daftar Pesanan)
- Use subtle dividers (1px, #F1F5F9). Each row should have a minimum height of 64px to ensure the "Remove" or "Edit Quantity" icons are easily tappable.

### Input Fields
- Background #F1F5F9 (slightly darker than the page) with no border. On focus, add a 1px solid stroke of #008080.

### Keypad
- Large, tactile buttons with 8px gaps. The "Enter/Pay" button should span two rows and use the Primary color.

### Status Chips
- For order statuses like "Diproses" (Processing) or "Selesai" (Done), use high-saturation text on low-saturation backgrounds (e.g., Green text on light green background).