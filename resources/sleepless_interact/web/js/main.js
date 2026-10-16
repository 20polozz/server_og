import { createOptions } from "./createOptions.js?v=pegatina0710f";
import { fetchNui } from "./fetchNui.js";
import { onSelect, setCurrentIndex, resetHold, setDefaultColor } from "./controls.js?v=pegatina0710f";

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;
let optionsVisible = false;

function playTextRevealSound() {
  try {
    const audio = new Audio("./transition.ogg");
    audio.volume = 0.45;
    audio.play().catch(() => { });
  } catch { }
}

function countOptions(options) {
  if (!options) return 0;

  let total = 0;
  for (const type in options) {
    total += options[type].length;
  }

  return total;
}

window.addEventListener("message", (event) => {
  switch (event.data.action) {
    case "visible": {
      body.style.visibility = event.data.value ? "visible" : "hidden";
      if (!event.data.value) {
        optionsVisible = false;
      }
      break
    }

    case "setOptions": {
      const nextOptionsCount = countOptions(event.data.value.options);

      optionsWrapper.innerHTML = "";

      if (event.data.value.options) {
        for (const type in event.data.value.options) {
          event.data.value.options[type].forEach((data, id) => {
            createOptions(type, data, id + 1);
          });
        }
        if (event.data.value.resetIndex) {
          setCurrentIndex(0);
        }
      }

      if (!optionsVisible && nextOptionsCount > 0) {
        playTextRevealSound();
      }

      optionsVisible = nextOptionsCount > 0;
      break
    }

    case "clearOptions": {
      optionsWrapper.innerHTML = "";
      optionsVisible = false;
      break
    }

    case "interact": {
      onSelect();
      break
    }

    case "release": {
      resetHold();
      break
    }

    case "setColor": {
      const c = event.data.value
      const color = `rgba(${c[0]}, ${c[1]}, ${c[2]}, ${c[3] / 255})`
      setDefaultColor(color)
      body.style.setProperty('--theme-color', color)
      break
    }

    case "setMarca": {
      const marca = event.data.value === "nacion" ? "nacion" : "origen";
      document.documentElement.dataset.marca = marca;
      window.postMessage({ accion: "origen:marca", marca }, "*");
      break
    }


    case "setCooldown": {
      body.style.opacity = event.data.value ? '0.3' : '1'
      const interactKey = document.getElementById("interact-key");

      interactKey.innerHTML = event.data.value ?  `<i class="fa-regular fa-hourglass-half"></i>` : 'E'

      break
    }
  }
});

window.addEventListener("load", async (event) => {
  await fetchNui("load");
});
