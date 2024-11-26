const colors = require("tailwindcss/colors");

const globalColors = {
  brand: {
    50: "#f0f9f5",
    100: "#dcf1e7",
    200: "#bce3d3",
    300: "#92cdb8",
    400: "#68b79c",
    500: "#47a183",
    600: "#3a846c",
    700: "#336b59",
    800: "#2d5548",
    900: "#26463c",
    950: "#1a2d27",
  },
  neutral: colors.slate,
  danger: {
    50: "#fef2f2",
    100: "#fee2e2",
    200: "#fecaca",
    300: "#fca5a5",
    400: "#f87171",
    500: "#ef4444",
    600: "#dc2626",
    700: "#b91c1c",
    800: "#991b1b",
    900: "#7f1d1d",
    950: "#450a0a",
  },
  error: colors.red,
  success: colors.green,
  warning: colors.amber,
};

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/components/**/*.erb",
    "./app/components/**/*.html",
    "./app/components/**/*.rb",
    "./app/lib/**/*.rb",
  ],
  theme: {
    extend: {
      colors: globalColors,
      backgroundColor: {
        "brand-primary": globalColors.brand[600],
        "brand-primary-hover": globalColors.brand[500],
        "brand-secondary": globalColors.brand[100],
        "brand-secondary-hover": globalColors.brand[200],
        "neutral-primary": colors.white,
        "neutral-secondary": globalColors.neutral[50],
        "danger-primary": globalColors.danger[600],
        "danger-primary-hover": globalColors.danger[500],
        "danger-secondary": globalColors.danger[100],
        "danger-secondary-hover": globalColors.danger[200],
      },
      borderColor: {
        "brand-primary": globalColors.brand[400],
        "neutral-primary": globalColors.brand[300],
        "danger-primary": globalColors.danger[400],
        "danger-secondary": globalColors.danger[300],
      },
      textColor: {
        "brand-onprimary": colors.white,
        "brand-onsecondary": globalColors.brand[800],
        "neutral-primary": globalColors.neutral[800],
        "neutral-secondary": globalColors.neutral[500],
        "neutral-emphasis": globalColors.neutral[900],
        "danger-onprimary": colors.white,
        "danger-onsecondary": globalColors.danger[800],
      },
    },
  },
  plugins: [],
};
