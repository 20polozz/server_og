# Vehicle Images

This folder is used to store custom vehicle images.

## How to use

1. Add your vehicle images to this folder
2. Name them using the vehicle model name with .png extension
   Example: `adder.png`, `t20.png`, `zentorno.png`

## Format

- Recommended format: PNG
- Recommended resolution: 300x200 pixels or higher
- File naming: Use the exact vehicle model name (lowercase)

## Fallback System

The system will automatically:
1. First try to load from this local folder: `./assets/vehicles/{model}.png`
2. If not found, try to load from FiveM docs: `https://docs.fivem.net/vehicles/{model}.webp`
3. If both fail, show a placeholder image
