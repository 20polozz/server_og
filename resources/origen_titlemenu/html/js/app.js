// Sonidos de interfaz en WAV, no en MP3: el MP3 mete unos 26 ms de silencio de
// codec al principio, y en un clic eso se percibe como retardo. Duran tan poco
// que el WAV pesa menos de 40 KB cada uno.
// unlock y glitch ya no se descargan de origennetwork.com: son locales, asi que
// el menu no depende de que esa web responda.
const s_click = new Audio('./sounds/click.wav');
const s_hover = new Audio('./sounds/over.wav');
const s_swipe = new Audio('./sounds/slide.wav');
const s_unlock = new Audio('./sounds/unlock.wav');
const s_glitch = new Audio('./sounds/glitch.wav');
// Volumenes recalibrados: los sonidos nuevos tienen picos distintos a los
// antiguos y con los valores de antes no se oian.
s_click.volume = 0.4;
s_hover.volume = 0.45;
s_unlock.volume = 0.9;
s_swipe.volume = 0.45;
s_glitch.volume = 0.35;
langs = async () => { return await $.post('https://origen_titlemenu/Nuitranslate', JSON.stringify({})) }
lang = null


translate = async () => {
	try {
		if (!lang) lang = await langs()
		updateTranslations(lang || await langs());
		debuger('^2 translate ready', lang)
	} catch (error) {
		debuger('^3[error]:^0', JSON.stringify(error));
	}

}

function updateTranslations(translate) {
	const elementsToTranslate = document.querySelectorAll('[translate]');
	elementsToTranslate.forEach(element => {
		const key = element.getAttribute('translate');
		if (translate?.hasOwnProperty(key)) {
			if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
				element.setAttribute('placeholder', translate[key]);
			} else {
				element.textContent = translate[key];
			}
		}
	});
}

const s_background = new Audio('https://origennetwork.com/music/v7/background.mp3');
s_background.volume = localStorage.getItem('ori_vol') || 0.45;

let selectedSlot;
let selectedCharacter;
let loadingSlot = false;
let cargaMenu = true;

// Sistema de bloqueo de selección de slots
let slotSelectionLocked = false;
let slotLockTimeout = null;

let btnSpawnLocation = false; //esta variable basicamente evita que spawneen el boton de aparacer aqui muchas veces 
let btnSpawnLocationFirst = false; //lo mismo que la de arriba pero para el primer spawn
let rpClockInterval = null;
let autoSelectTimeout = null;
let lastSelectCharacterRequest = null;
let activeThemeProfile = null;

const debuger = async (...a) => {
	const activeDebug = await $.post('https://origen_titlemenu/GetDebug', JSON.stringify({}), function (active) {
		return active
	})
	// if (activeDebug) console.log('^4[ORIGEN TITLEMENU]:NUI^0', ...a)
}

function applyThemeProfile(themeProfile) {
	if (!themeProfile || typeof themeProfile !== 'object') return;
	activeThemeProfile = themeProfile;

	const colors = themeProfile.colors || {};
	const branding = themeProfile.branding || {};
	const root = document.documentElement;

	if (colors.primary) root.style.setProperty('--primary-color', colors.primary);
	if (colors.border) root.style.setProperty('--border-color', colors.border);
	if (colors.borderHover) root.style.setProperty('--border-color-hover', colors.borderHover);
	if (colors.glow) root.style.setProperty('--glow-magenta', colors.glow);

	if (branding.backgroundImage) {
		root.style.setProperty('--menu-bg-image', `url(${branding.backgroundImage})`);
	}

	if (branding.serverName) {
		const serverNameEl = document.getElementById('brand-server-name');
		if (serverNameEl) serverNameEl.textContent = branding.serverName;
	}

	if (branding.heroDescription) {
		const heroDescriptionEl = document.getElementById('brand-hero-description');
		if (heroDescriptionEl) heroDescriptionEl.textContent = branding.heroDescription;
	}

	if (branding.discordUrl) {
		const discordEl = document.getElementById('brand-discord-link');
		if (discordEl) discordEl.setAttribute('url', branding.discordUrl);
	}

	if (branding.youtubeUrl) {
		const youtubeEl = document.getElementById('brand-youtube-link');
		if (youtubeEl) youtubeEl.setAttribute('url', branding.youtubeUrl);
	}

	if (branding.logo) {
		const logoMain = document.getElementById('brand-logo-main');
		if (logoMain) logoMain.setAttribute('src', branding.logo);
	}
}

const origenGeneral = [
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
];

const origenDelictivos = [
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
	'./assets/example_normativa.png',
];

const config = {
	servers: [
		{
			name: 'Origen Los Santos',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/elorigenrp'
		},
		{
			name: 'Origen New York',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/MQ7bbDqp82'
		},
		{
			name: 'Evolución Los Santos',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/rphDrK47Ag'
		},
		{
			name: 'Evolución New York',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/rphDrK47Ag'
		},
		{
			name: 'Nación Online',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/Nax9CfwwcJ'
		},
		{
			name: 'Invasión Z',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/u6z6YUx99X'
		},
		{
			name: 'OrigenCraft',
			logo: './assets/logo.png',
			discord: 'https://discord.gg/9VHN8jvHYb'
		},
	],
	normativa: {
		general: origenGeneral,
		delictivos: origenDelictivos
	},
	controls: [
		{ key: 'F1', description: 'VER TELEFONO MOVIL' },
		{ key: 'F2', description: 'ABRIR INVENTARIO DE JUGADOR' },
		{ key: 'F3', description: 'MENU DE OPCIONES PERSONALES' },
		{ key: 'F6', description: 'MENU DE TRABAJOS GENERALES' },
		{ key: 'F7', description: 'MENU DE FACTURAS Y BILLS GENERALES' },
		{ key: 'B', description: 'APUNTAR CON EL DEDO' },
		{ key: 'G', description: 'CRUZAR BRAZOS' },
		{ key: 'X', description: 'LEVANTAR BRAZOS' },
		{ key: 'ESC', description: 'Interfaz De Menu De Pausa' },
	]
};

document.addEventListener('DOMContentLoaded', () => {
	const container = document.getElementById('controls-container');

	// La landing ahora la renderiza Vue (source-ui/), que trae su propio marcado,
	// asi que #controls-container ya no existe. Sin esta guarda el appendChild de
	// abajo revienta y se lleva por delante el resto del handler.
	if (!container) {
		loadRules();
		return;
	}

	config.controls.forEach(control => {
		const controlItem = document.createElement('div');
		controlItem.classList.add('modern-control-item');

		const keyDiv = document.createElement('div');
		keyDiv.classList.add('modern-key');
		keyDiv.textContent = control.key;

		const descDiv = document.createElement('div');
		descDiv.classList.add('modern-desc');
		descDiv.textContent = control.description;

		controlItem.appendChild(keyDiv);
		controlItem.appendChild(descDiv);

		container.appendChild(controlItem);
	});

	// Cargar reglas generales
	loadRules();
});


// OJO: aqui solo van las clases del menu ANTIGUO. La landing en Vue lleva su
// propia capa de sonido (source-ui/src/composables/useSonidos.js), que decide
// por rol en vez de por nombre de clase. Si se añaden aqui clases del diseño
// nuevo, cada clic sonaria dos veces.
$(document).on(
	'click',
	'.btn-iniciar, .btn-menu, .back-button, .web-button, .select-button, .link, .spawn, .btn-aparecer, .nav-link, .social-btn, .about-btn, .hero-btn',
	function () {
		s_click.currentTime = '0';
		s_click.play();
	}
);

// Confirmacion al entrar de verdad: el disparador oculto solo se pulsa cuando
// se completa el mantenido, asi que este sonido marca ese momento y no un clic
// suelto sobre la celda.
$(document).on('click', '#start-play', function () {
	s_unlock.currentTime = '0';
	s_unlock.play();
});

$(document).on(
	'mouseenter',
	'.btn-iniciar, .btn-menu, .slot, .back-button, .web-button, .select-button, .link, .spawn, .btn-aparecer, .nav-link, .social-btn, .stat-card, .rule-card, .modern-control-item, .about-stat-card, .about-btn, .hero-btn, .feature-item',
	function () {
		s_hover.currentTime = "0";
		s_hover.play();
	}
);

$(document).on('click', '#nav-home', function () {
	s_swipe.currentTime = '0';
	s_swipe.play();
	$('.nav-link').removeClass('active');
	$(this).addClass('active');
	$('.modern-content').show();
	$('.secciones').removeClass('show').hide();
	$('.info-bar.top').removeClass('back');
});

// Botón EMPEZAR A JUGAR
$(document).on('click', '#start-play', function () {
	s_swipe.currentTime = '0';
	s_swipe.play();
	// El cartel "Preparando personajes..." se ha quitado: la pantalla de carga
	// del servidor ya cubre esta transicion y se solapaban.
	fetch('HudFadeOut', { time: 380 }).always(() => {
		fetch('StartCinematicCam', {});
		setTimeout(() => {
			$('.home-screen').addClass('hide');
			setTimeout(() => {
				$('.menu-container.principal').fadeOut(1000, function () {
					$('.back-button.slots-selection')
						.removeClass('animate__fadeOutUp')
						.addClass('animate__fadeInDown');
					$('.slots-container .bottom-bar')
						.removeClass('animate__fadeOutDown')
						.addClass('animate__fadeInUp')
						.fadeIn(700);
					$('.btn-menu').removeClass('active');
					applyPreloadedDefaultSelection(false);
					$('.menu-container.slots-container').fadeIn(1000, function () {
						scheduleAutoSelectDefaultSlot(250);
						ensureSelectedCharacterPreview(0);
						fetch('HudFadeIn', { time: 380 });
						$('.loading-container').fadeOut(220);
					});
				});
			}, 500);
		}, 300);
	});
});

// Pantalla de access removida - ya no se usa

$(document).on('click', '.menu-section.home-screen #mis-personajes', function () {
	// Mismo motivo que en #start-play: el cartel sobraba sobre la pantalla de
	// carga del servidor.
	fetch('HudFadeOut', { time: 380 }).always(() => {
		fetch('StartCinematicCam', {});
		$('.home-screen').addClass('hide');
		setTimeout(() => {
			$('.menu-container.principal').fadeOut(1000, function () {
				$('.back-button.slots-selection')
					.removeClass('animate__fadeOutUp')
					.addClass('animate__fadeInDown');
				$('.slots-container .bottom-bar')
					.removeClass('animate__fadeOutDown')
					.addClass('animate__fadeInUp')
					.fadeIn(700);
				$('.btn-menu').removeClass('active');
				applyPreloadedDefaultSelection(false);
				$('.menu-container.slots-container').fadeIn(1000, function () {
					scheduleAutoSelectDefaultSlot(250);
					ensureSelectedCharacterPreview(0);
					fetch('HudFadeIn', { time: 380 });
					$('.loading-container').fadeOut(220);
				});
			});
		}, 500);
	});
});

$(document).on('click', '.slot', function () {
	// Verificar si el slot está bloqueado (sin desbloquear)
	if ($(this).hasClass('bloqueado')) {
		debuger('No puedes seleccionar un slot bloqueado');
		return;
	}

	// Verificar si el slot ya está seleccionado
	if ($(this).hasClass('selected')) {
		debuger('Este slot ya está seleccionado');
		return;
	}

	// Verificar si la selección de slots está bloqueada
	if (slotSelectionLocked) {
		debuger('Selección de slots bloqueada. Espera unos segundos...');
		return;
	}

	if (!loadingSlot) {
		loadingSlot = true;
		s_click.currentTime = '0';
		s_click.play();
		$('.select-button')
			.removeClass('accesible')
			.html(
				"<div class='container-select'><img src='assets/loading.svg' style='width:calc(5vh / var(--ogn-escala, 1));'></div>"
			);
		$('.info-pj').removeClass('show');
		$('.stat-progress .stat-bar').css('width', '0%');

		// Seleccionar el slot y actualizar el botón según su estado
		selectedSlot = $(this);

		$('.slot.selected').removeClass('selected');
		$(this).addClass('selected');

		if (!$(this).hasClass('bloqueado')) {
			// BLOQUEAR SELECCIÓN DE SLOTS POR 6 SEGUNDOS
			slotSelectionLocked = true;
			$('.slot').addClass('locked');

			// Cancelar timeout anterior si existe
			if (slotLockTimeout) {
				clearTimeout(slotLockTimeout);
			}

			// Crear nuevo timeout de 6 segundos
			slotLockTimeout = setTimeout(() => {
				slotSelectionLocked = false;
				$('.slot').removeClass('locked');
				debuger('Slots desbloqueados - puedes seleccionar otro slot');
			}, 7000);
		}

		if ($(this).hasClass('bloqueado')) {
			fetch('UnselectCharacter', {});

			$('.select-button').html(
				"<div class='container-select'><i class='fa-solid fa-check'></i> Slot bloqueado</div>"
			);
			setTimeout(() => {
				loadingSlot = false;
			}, 500);
		} else if ($(this).hasClass('desbloqueado')) {
			// fetch("UnselectCharacter", {});
			fetch('StartCharacterCreation', {});

			$('.select-button').addClass('accesible').attr('action', 'register');
			$('.select-button').addClass('accesible');
			$('.select-button').html(
				"<div class='container-select'>Crear personaje</div>"
			);

			setTimeout(() => {
				loadingSlot = false;
			}, 500);
		} else if ($(this).hasClass('creado')) {
			const citizenid = $(this).attr('citizenid');
			fetch('SelectCharacter', { citizenid }).then((data) => {
				if (data) {
					setCharacterInfo($(this).attr('slot'));

					$('.select-button')
						.addClass('accesible')
						.attr('action', 'access');
					$('.select-button').addClass('accesible');
					$('.select-button').html(
						"<div class='container-select'>Ubicación</div>"
					);
					$('.info-pj').addClass('show');

					setTimeout(() => {
						loadingSlot = false;
					}, 500);
				}
			});
		}
	}
});

$(document).on('click', '.select-button.accesible', function () {
	if ($(this).attr('action') == 'register') {
		// $.post("https://origen_titlemenu/RegisterCharacter");
		s_swipe.currentTime = '0';
		s_swipe.play();
		$('.register .back-button')
			.removeClass('animate__fadeOutUp')
			.addClass('animate__fadeInDown');

		openRegister();
	} else if ($(this).attr('action') == 'access') {
		s_swipe.currentTime = '0';
		s_swipe.play();
		fetch('HudFadeOut', { time: 420 }).always(() => {
			loadPlayerSlot();
			$.post('https://origen_titlemenu/AccessCharacter');
		});
	}
});

$(document).on('click', '.back-button.slots-selection', function () {
	s_swipe.currentTime = '0';
	s_swipe.play();
	$('.back-button.slots-selection')
		.removeClass('animate__fadeInDown')
		.addClass('animate__fadeOutUp');
	$('.slots-container .slot.selected').removeClass('selected');
	$('.info-pj').removeClass('show');
	$('.slots-container .bottom-bar')
		.removeClass('animate__fadeInUp')
		.addClass('animate__fadeOutDown')
		.fadeOut(700);
	$('.menu-container.slots-container').fadeOut(1000, function () {
		fetch('UnselectCharacter', {});
		fetch('StopCinematicCam', {});

		// Limpiar el sistema de bloqueo de slots
		if (slotLockTimeout) {
			clearTimeout(slotLockTimeout);
			slotLockTimeout = null;
		}
		slotSelectionLocked = false;
		$('.slot').removeClass('locked');

		$('.select-button')
			.removeClass('accesible')
			.html("<div class='container-select'>ELIGE UN SLOT</div>");

		$('.menu-container.principal').fadeIn(1000, function () {
			$('.home-screen').removeClass('hide');
		});
	});
});

$(document).on('click', '.register .back-button', function () {
	s_swipe.currentTime = '0';
	s_swipe.play();
	$('.register .back-button')
		.removeClass('animate__fadeInDown')
		.addClass('animate__fadeOutUp');

	$('.register')
		.removeClass('show')
		.fadeOut(300, function () {
			fetch('StartCharacterCreation', {});

			$('.back-button.slots-selection')
				.removeClass('animate__fadeOutUp')
				.addClass('animate__fadeInDown');
			$('.slots-container .bottom-bar')
				.removeClass('animate__fadeOutDown')
				.addClass('animate__fadeInUp')
				.fadeIn(700);
		});
});

$(document).on('click', '.spawn-selector .back-button', function () {
	s_swipe.currentTime = '0';
	s_swipe.play();
	stopRpClock();
	btnSpawnLocation = false;
	btnSpawnLocationFirst = false;

	const citizenid =
		(selectedSlot && selectedSlot.length && selectedSlot.attr('citizenid')) ||
		(selectedCharacter && selectedCharacter.citizenid) ||
		null;

	fetch('HudFadeOut', { time: 380 }).always(() => {
		if (citizenid) {
			fetch('BackToCharacterSelection', { citizenid });
		}

		$('.spawn-selection .back-button')
			.removeClass('animate__fadeInDown')
			.addClass('animate__fadeOutUp');
		$('.info-pj').addClass('show');
		$('.spawn-selector')
			.removeClass('show')
			.fadeOut(120, function () {
				if (typeof destruirMapaCentral === 'function') {
					destruirMapaCentral();
				}
				$('.back-button.slots-selection')
					.removeClass('animate__fadeOutUp')
					.addClass('animate__fadeInDown');
				$('.slots-container .bottom-bar')
					.removeClass('animate__fadeOutDown')
					.addClass('animate__fadeInUp')
					.fadeIn(250, function () {
						fetch('HudFadeIn', { time: 380 });
					});
			});
	});
});

$(document).on('click', '.genero', function () {
	$('.genero').removeClass('selected');
	$(this).addClass('selected');
	if ($(this).attr('genero') == '0') {
		fetch('SetModel', { model: 'mp_m_freemode_01' });
	} else {
		fetch('SetModel', { model: 'mp_f_freemode_01' });
	}

	checkRegisterValidation();
});

$(document).on('focusout', '.register .register-data .input-register', function () {
	const validation = $(this).attr('validation');

	let regex =
		$(this).hasClass('name') || $(this).hasClass('surname')
			? /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]{3,}$/
			: /^(0[1-9]|[12][0-9]|3[01])[- \/.](0[1-9]|1[012])[- \/.](19|20)\d{2}$/;

	// Check if the input value matches the regular expression
	setTimeout(() => {
		if (regex.test($(this).val())) {
			// If the input value matches the regular expression, show success message
			$('.validation.' + validation)
				.removeClass('error success')
				.fadeOut(300, function () {
					$('.validation.' + validation)
						.html('<img src="assets/check.webp">')
						.addClass('success')
						.fadeIn(300);
					checkRegisterValidation();
				});
		} else {
			// If the input value does not match the regular expression, show error message
			$('.validation.' + validation)
				.removeClass('error success')
				.fadeOut(300, function () {
					$('.validation.' + validation)
						.html('<img src="assets/error.webp">')
						.addClass('error')
						.fadeIn(300);
					checkRegisterValidation();
				});
		}
	}, 100);
});

$(document).on('click', '.confirm-slot', function () {
	$('.unlock').fadeOut(300);
});

function capitalize(string) {
	return string.charAt(0).toUpperCase() + string.slice(1);
}

$(document).on('click', '.btn-register', function () {
	if (checkRegisterValidation()) {
		s_swipe.currentTime = '0';
		s_swipe.play();
		$('.blackscreen').fadeIn(300, function () {
			$('.register').fadeOut(300, function () {
				$('.register .back-button')
					.removeClass('animate__fadeInDown')
					.addClass('animate__fadeOutUp');
				$('.register')
					.removeClass('show')
					.fadeOut(0, function () {
						$('.back-button.slots-selection')
							.removeClass('animate__fadeOutUp')
							.addClass('animate__fadeInDown');
						// resetMenu();
					});
				const cid = parseInt(selectedSlot.attr('slot'));

				let nationality = $('#country').val().trim();
				//Comprobamos si nationality tiene parentesis y si los tiene, los quitamos
				if (nationality.includes('(')) {
					nationality = nationality.split('(')[1].replace(')', '');
				}

				TriggerCallback('origen_titlemenu:server:CreateCharacter', {
					charinfo: {
						firstname: capitalize($('.register .input-register.name').val()),
						lastname: capitalize($('.register .input-register.surname').val()),
						nationality,
						birthdate: $('.register .input-register.date').val(),
						gender: parseInt($('.register .genero.selected').attr('genero'))
					},
					cid
				}).then((data) => {
					debuger(data);
					if (data) {
						selectedSlot.attr('citizenid', data.citizenid);

						// Check if we should skip spawn selection
						fetch("GetSpawns", { citizenid: data.citizenid }).then((spawnData) => {
							if (spawnData && spawnData.skipSpawnSelection && spawnData.spawns && spawnData.spawns.length > 0) {
								// Skip spawn selector completely, go directly to character creation
								const spawn = spawnData.spawns[0];

								setTimeout(() => {
									$('.loading-container').fadeOut(300, function () {
										$('.register')
											.removeClass('animate__fadeInDown')
											.addClass('animate__fadeOutUp');
										$('.register')
											.removeClass('show')
											.fadeOut(0, function () {
												$('.back-button.spawn-selection')
													.removeClass('animate__fadeInDown')
													.addClass('animate__fadeOutUp');

												// Don't show spawn selector, directly trigger character creation
												TriggerCallback('origen_titlemenu:server:SpawnPlayer', {
													citizenid: data.citizenid,
													type: spawn.type,
													id: spawn.id,
													apartmentType: spawn.apartmentType
												}).then((spawnResult) => {
													if (spawnResult) {
														window.parent.document.getElementsByName('origen_loadingasset')[0].contentWindow.postMessage({ action: "stopMusic" }, "*");
														setTimeout(() => {
															$('.blackscreen').fadeOut(300);
															$('.menu-container').fadeOut(300);
														}, 1500);
													}
												});
											});
									});
								}, 3000);
							} else {
								// Normal flow - show spawn selector
								setTimeout(() => {
									$('.loading-container').fadeOut(300, function () {
										$('.register')
											.removeClass('animate__fadeInDown')
											.addClass('animate__fadeOutUp');
										$('.register')
											.removeClass('show')
											.fadeOut(300, function () {
												$('.back-button.spawn-selection')
													.removeClass('animate__fadeInDown')
													.addClass('animate__fadeOutUp');
												$('.blackscreen').fadeOut(300, function () {
													loadSpawnSelector();
												});
											});
									});
								}, 3000);
							}
						});
					}
				});
			});

			$('.loading-container').fadeIn(300);
		});
	}
});

$(document).on('click', '.spawn-buttons .spawn.location', function () {
	$('.spawn-buttons .spawn.active').removeClass('active');
	$(this).addClass('active');
	const id = $(this).attr('id').split('-')[1];
	const x = parseFloat($(this).attr('x'));
	const y = parseFloat($(this).attr('y'));
	fetch('SelectSpawn', { x, y });
	$('.btn-aparecer')
		.html(`${lang.wake_up || 'Despertarse'} <i class="lni lni-angle-double-right"></i>`)
		.addClass('active')
		.addClass('location');
	if (window.renderSpawnSpotlightFromElement) {
		window.renderSpawnSpotlightFromElement(this);
	}
	mapFunctions.setAlertFocus(id);
});

$(document).on('click', '.spawn-buttons .spawn.first', function () {
	$('.spawn-buttons .spawn.active').removeClass('active');
	$(this).addClass('active');
	const id = $(this).attr('id').split('-')[1];
	const x = parseFloat($(this).attr('x'));
	const y = parseFloat($(this).attr('y'));
	fetch('SelectSpawn', { x, y });

	$('.btn-aparecer')
		.html(`${lang.wake_up || 'Despertarse'} <i class="lni lni-angle-double-right"></i>`)
		.addClass('active')
		.addClass('first');
	if (window.renderSpawnSpotlightFromElement) {
		window.renderSpawnSpotlightFromElement(this);
	}
	mapFunctions.setAlertFocus(id);
});

$(document).on('click', '.btn-aparecer.active', function () {
	const spawnData = window.currentSelectedSpawn || null;
	if (!spawnData) return;

	const isFirstSpawn = spawnData.option || spawnData.type === 'first_apartment';
	if (isFirstSpawn) {
		if (btnSpawnLocationFirst) return;
		btnSpawnLocationFirst = true;
	} else {
		if (btnSpawnLocation) return;
		btnSpawnLocation = true;
	}

	const type = spawnData.type;
	const spawnId = spawnData.name || spawnData.id;
	const apartmentType = spawnData.apartmentType;

	$('.spawn-selection .back-button')
		.removeClass('animate__fadeInDown')
		.addClass('animate__fadeOutUp');
	$('.spawn-selector')
		.removeClass('show')
		.fadeOut(300, function () {
			s_swipe.currentTime = '0';
			s_swipe.play();
			$('.loading-container .text').html(
				isFirstSpawn
					? (lang.buy_property || 'Preparando tu punto de inicio...')
					: (lang.loanding_ubi || 'Despertando en tu última ubicación...')
			);
			$('.loading-container').fadeIn(300);
			debuger('Info spawn:', {
				citizenid: selectedSlot.attr('citizenid'),
				type,
				id: spawnId,
				apartmentType,
				firstname: selectedCharacter?.firstname,
				lastname: selectedCharacter?.lastname
			});

			TriggerCallback('origen_titlemenu:server:SpawnPlayer', {
				citizenid: selectedSlot.attr('citizenid'),
				type,
				id: spawnId,
				apartmentType,
				firstname: selectedCharacter?.firstname,
				lastname: selectedCharacter?.lastname
			}).then((data) => {
				debuger('Spawn data:', data);
				if (data) {
					window.parent.document.getElementsByName('origen_loadingasset')[0].contentWindow.postMessage({ action: "stopMusic" }, "*");
					setTimeout(() => {
						sendIframeMessage("music-frame", "stopMusic");
						$('.loading-container').fadeOut(300, function () {
							$('.menu-container').fadeOut(300);
						});
					}, 1500);
				}
			});
		});
});

$(document).on('click', '.menu-section.home-screen .seccion-nav', function () {
	const seccion = $(this).attr('seccion');
	$('.nav-link').removeClass('active');
	$(this).addClass('active');
	// Ocultar hero section
	// $('.hero-section').hide();
	$('.modern-content').hide();
	loadSection(seccion);
});

// Función para cargar reglas en formato moderno
function loadRules() {
	const generalRules = [
		'No se permite el uso de programas externos que otorguen algun tipo de ventaja y el uso de cheats, hacks o exploits.',
		'No abusar de bugs o fallos del servidor (exploits). Si encuentras uno, debes reportarlo al staff.',
		'Prohibido hacer MetaGaming y PowerGaming.',
		'Rol serio y realista.',
		'Uso correcto de comandos /me /do /entorno entre otros.',
		'Zonas seguras. En ellas esta prohibido robar, secuestrar, disparar o generar situaciones violentas.',
		'Valorar la vida. Tu personaje debe actuar como si su vida importara. No puedes hacer cosas suicidas o imposibles sin un motivo de rol logico.',
		'Respeto obligatorio. Prohibido insultar, provocar, discriminar o acosar a otros jugadores o al staff, tanto IC como OOC.',
		'Interpretacion del personaje. El personaje debe mantener una personalidad coherente y una evolucion logica.',
		'Recordad leer, entender y respetar la normativa facilitada en el discord oficial y estar atentos a futuras actualizaciones de esta misma. El desconocimiento de normas no exime de sancion.'
	];

	const ilegalRules = [
		'No iniciar roles o actos criminales 15 min antes o despues de reinicios (30 min para atracos), salvo que el rol ya estuviera en curso.',
		'Prohibido usar accesorios no permitidos en roles agresivos. No se permiten cascos de guerra u otros objetos que tankean sin justificacion de personaje o banda.',
		'Antes de usar un arma, debes dar tiempo suficiente para que la otra persona reaccione y cumpla. Si te matan, no puedes volver a la zona a continuar el rol.',
		'No robar sin rol previo. Robar a jugadores sin rol previo para farmear dinero o items esta prohibido.',
		'Prohibido el campeo de puntos, atracos y robos.',
		'No se puede forzar a retirar dinero del banco y robarselo.',
		'Robos en puntos interactivos. No se puede robar a jugadores que esten en puntos como tiendas de ropa, tiendas de tatuajes o negocios interactivos.',
		'Respetar el numero maximo de integrantes en roles agresivos, robos y atracos.',
		'Uso de armas desde vehiculos: Puedes pinchar ruedas desde un coche en marcha, pero prohibido disparar a matar o usar el vehiculo a modo de arma contra jugadores a pie.',
		'Entorno obligatorio en acciones ilegales. En cualquier acto criminal debes enviar entorno (descripcion detallada de ropa, vehiculos, colores, etc.). No enviarlo puede ser sancionado.'
	];

	const generalContainer = $('.rules-cards-container');
	const ilegalContainer = $('.rules-cards-container-ilegal');

	generalRules.forEach((rule, index) => {
		generalContainer.append(`
			<div class="rule-card animate__animated animate__fadeInLeft" style="animation-delay:${index * 0.1}s">
				<div class="rule-number">${index + 1}</div>
				<div class="rule-text">${rule}</div>
			</div>
		`);
	});

	ilegalRules.forEach((rule, index) => {
		ilegalContainer.append(`
			<div class="rule-card animate__animated animate__fadeInRight" style="animation-delay:${index * 0.1}s">
				<div class="rule-number">${index + 1}</div>
				<div class="rule-text">${rule}</div>
			</div>
		`);
	});
}

$(document).ready(async () => {

	$.post('https://origen_titlemenu/Ready', JSON.stringify({}), function (confirm) {
		if (confirm) {
			translate()
			$('.menu-section').hide();
			$('.home-screen').show();
			if (localStorage.getItem('ori_vol') != null) {
				$('#progress-volumen').val(localStorage.getItem('ori_vol') * 2 * 100);
				setVolumeIcon(localStorage.getItem('ori_vol') * 2 * 100);
			} else {
				$('#progress-volumen').val(80);
				setVolumeIcon(80);
			}

			$('#progress-volumen').value;
			// debuger(localStorage.getItem('ori_vol') * 2);
			s_background.currentTime = '0';
			// Si el marco de la musica no esta, esto reventaba antes del fadeIn
			// y el menu se quedaba escondido: pantalla negra.
			try {
				window.parent.document.getElementsByName('origen_loadingasset')[0].contentWindow.postMessage({ action: "normalizaMusicVolume", volume: localStorage.getItem("ori_vol") }, "*");
			} catch (e) {
				console.error('[origen_titlemenu] Sin marco de musica: ' + e.message);
			}
			// s_background.play();

			// Iniciar actualización de stats
			startStatsUpdate();

			$('.menu-container.principal').fadeIn(1000);
		}
	});
});

function startStatsUpdate() {

}

function setConfiguratorPreview(show) {
	const slotsContainer = $('.menu-container.slots-container');
	const firstSlot = $(".slots .slot[slot='1']");

	if (show) {
		$('.menu-container.principal').hide();
		$('.menu-section').hide();
		$('.secciones').hide();
		$('.register').hide();
		$('.spawn-selector').hide();
		$('.unlock').hide();
		$('.blackscreen').hide();
		$('.loading-container').hide();

		slotsContainer.show();
		$('.slots-container .bottom-bar')
			.stop(true, true)
			.show()
			.removeClass('animate__fadeOutDown')
			.addClass('animate__fadeInUp');
		$('.back-button.slots-selection').hide();

		$('.slot').removeClass('selected');
		if (firstSlot.length) {
			firstSlot.addClass('selected');
		}

		$('.info-pj').addClass('show');
		$('.select-button')
			.addClass('accesible')
			.attr('action', 'access')
			.html("<div class='container-select'>Ubicación</div>");
	} else {
		$('.slot').removeClass('selected');
		$('.info-pj').removeClass('show');
		$('.slots-container .bottom-bar').hide();
		slotsContainer.hide();
	}
}

/* Con la partida ya empezada no pinta nada. Si el recurso se reinicia a mitad
   de partida la pagina arranca de cero, en la portada, y tapaba la pantalla
   entera sin forma de quitarla; Lua lo detecta y manda `ocultarEnPartida`.
   El siguiente `setup` (la proxima vez que entres) la vuelve a enseñar. */
function mostrarPagina(si) {
	var el = document.getElementById('ogn-oculta-en-partida');
	if (!si && !el) {
		el = document.createElement('style');
		el.id = 'ogn-oculta-en-partida';
		el.textContent = 'html{display:none !important}';
		document.head.appendChild(el);
	} else if (si && el) {
		el.remove();
	}
}

window.addEventListener('message', function (event) {
	if (event.data.action == 'ocultarEnPartida') {
		mostrarPagina(false);
		return;
	}
	if (event.data.action == 'setup' || event.data.action == 'logout') mostrarPagina(true);
	if (event.data.action == 'setup') {
		applyThemeProfile(event.data.themeProfile);
		debuger(event.data.characters);
		characters = event.data.characters;
		setupSlots(characters, event.data.slots);
		debuger('Me llega setup');
	} else if (event.data.action == 'logout') {
		resetMenu();
	} else if (event.data.action == 'entrado') {
		// Lua avisa al terminar el spawn (tambien si fallo a medias): el menu y
		// la carga fuera, que no queden pintados sobre el juego sin raton.
		$('.loading-container').stop(true, true).hide();
		$('.menu-container').stop(true, true).hide();
	} else if (event.data.action == 'updatePlayerCount') {
		$('#players-online').text(`${event.data.playerCount}/${event.data.maxPlayers}`);
	} else if (event.data.action == 'updateStaffCount') {
		$('#staff-online').text(event.data.staffCount);
	} else if (event.data.action == 'updateUptime') {
		const hours = Math.floor(event.data.uptimeMinutes / 60);
		const minutes = event.data.uptimeMinutes % 60;
		$('#server-uptime').text(`${hours}h ${minutes}m`);
	} else if (event.data.action == 'updateServerInfo') {
		if (event.data.ping) $('#server-latency').text(event.data.ping + 'MS');
		if (event.data.version) $('#server-version').text(event.data.version);
	} else if (event.data.action == 'configPreview') {
		setConfiguratorPreview(!!event.data.show);
	}
});

function loadSliders() {
	// Función simplificada - ya no necesitamos los sliders
	debuger('Sliders deshabilitados - usando nuevo diseño moderno');
}

function openRegister() {
	$('.genero').removeClass('selected');
	// const cid = $(".slots-container .slot.selected").attr("slot");
	// $(".back-button.slots-selection").removeClass("animate__fadeInDown").addClass("animate__fadeOutUp");
	$('.slots-container .bottom-bar')
		.removeClass('animate__fadeInUp')
		.addClass('animate__fadeOutDown')
		.fadeOut(500, function () {
			$('.back-button.slots-selection')
				.removeClass('animate__fadeInDown')
				.addClass('animate__fadeOutUp');

			$('.info-pj').removeClass('show');
			$('.slots-container .register').fadeIn(300, function () {
				$('.slots-container .register').addClass('show');
			});
		});
}

function loadPlayerSlot() {
	$('.btn-aparecer').text(lang.wake_up || 'DESPERTARSE').removeClass('active');
	$('.back-button.slots-selection')
		.removeClass('animate__fadeInDown')
		.addClass('animate__fadeOutUp');
	$('.info-pj').removeClass('show');
	$('.slots-container .bottom-bar')
		.removeClass('animate__fadeInUp')
		.addClass('animate__fadeOutDown')
		.fadeOut(700, function () {
			loadSpawnSelector();
		});
}

function checkRegisterValidation() {
	let validate = false;

	let nationality = $('#country').val().trim();

	let firstname = $('.register .input-register.name').val();
	let lastname = capitalize($('.register .input-register.surname').val());
	let birthdate = $('.register .input-register.date').val();

	if ($('.genero.selected').length == 1 && nationality && firstname && lastname && birthdate) {
		$('.btn-register').removeClass('disabled');
		validate = true;
	} else {
		$('.btn-register').addClass('disabled');
	}

	return validate;
}

function setupSlots(characters, slots) {
	debuger('[setupSlots] Iniciando configuración de slots', 'Slots disponibles:', slots, 'Personajes recibidos:', characters ? characters.length : 0);
	debuger('[setupSlots] Datos de personajes:', characters);

	$('.slot').addClass('bloqueado');

	if (slots) {
		for (let i = 1; i <= slots; i++) {
			$(".slot[slot='" + i + "']").removeClass('bloqueado').addClass('desbloqueado').find('.slot-name').removeAttr('translate').text(lang?.unlock_s || 'Slot desbloqueado');
			debuger('[setupSlots] Slot', i, 'desbloqueado');
		};
	}

	if (characters) {
		$('.slot .img-slot').removeClass('hasPlayer');
		Object.values(characters).map((character) => {
			debuger('[setupSlots] Configurando personaje:', character.firstname, character.lastname, 'en slot', character.cid);
			// debuger(character.mugshot);
			// debuger($(".slot[slot='"+character.cid+"'] .img-slot").html());
			$(".slot[slot='" + character.cid + "']")
				.removeClass('desbloqueado')
				.removeClass('bloqueado')
				.addClass('creado')
				.attr('citizenid', character.citizenid);
			$(".slot[slot='" + character.cid + "'] .img-slot")
				.html(
					`<i class="fa-solid fa-user-tie slot-char-icon"></i>`
				)
				.addClass('hasPlayer');
			$(".slot[slot='" + character.cid + "']")
				.find('.slot-name')
				.removeAttr('translate')
				.text(character.firstname + ' ' + character.lastname);
		});
		debuger('[setupSlots] Total de personajes configurados:', Object.values(characters).length);
	} else {
		debuger('[setupSlots] ⚠️ ADVERTENCIA: No se recibieron personajes!');
	}

	cargaMenu = false;

	if ($('.menu-container.slots-container').is(':visible')) {
		if (!applyPreloadedDefaultSelection(true)) {
			scheduleAutoSelectDefaultSlot(150);
		}
	}
}

function getDefaultCreatedSlotElement() {
	const slotOne = $(".slots .slot[slot='1']");
	if (slotOne.length && slotOne.hasClass('creado')) {
		return slotOne;
	}

	const firstCreated = $('.slots .slot.creado').first();
	return firstCreated.length ? firstCreated : null;
}

function applyPreloadedDefaultSelection(triggerServerSelect = true) {
	const targetSlot = getDefaultCreatedSlotElement();
	if (!targetSlot || !targetSlot.length) return false;

	selectedSlot = targetSlot;
	$('.slot.selected').removeClass('selected');
	targetSlot.addClass('selected');

	const slotNumber = parseInt(targetSlot.attr('slot'), 10);
	if (!Number.isNaN(slotNumber)) {
		setCharacterInfo(slotNumber);
	}

	$('.select-button')
		.addClass('accesible')
		.attr('action', 'access')
		.html("<div class='container-select'>Ubicación</div>");

	$('.info-pj').addClass('show');

	if (triggerServerSelect) {
		const citizenid = targetSlot.attr('citizenid');
		if (citizenid && lastSelectCharacterRequest !== citizenid) {
			lastSelectCharacterRequest = citizenid;
			fetch('SelectCharacter', { citizenid });
		}
	}

	return true;
}

function scheduleAutoSelectDefaultSlot(delay = 250) {
	if (autoSelectTimeout) {
		clearTimeout(autoSelectTimeout);
		autoSelectTimeout = null;
	}

	autoSelectTimeout = setTimeout(() => {
		tryAutoSelectDefaultSlot(0);
	}, delay);
}

function ensureSelectedCharacterPreview(attempt = 0) {
	if (!$('.menu-container.slots-container').is(':visible')) return;

	const selected = $('.slots .slot.selected').first();
	if (!selected.length) {
		if (attempt < 15) setTimeout(() => ensureSelectedCharacterPreview(attempt + 1), 120);
		return;
	}

	const citizenid = selected.attr('citizenid');
	if (!citizenid) {
		if (attempt < 15) setTimeout(() => ensureSelectedCharacterPreview(attempt + 1), 120);
		return;
	}

	if (lastSelectCharacterRequest !== citizenid) {
		lastSelectCharacterRequest = citizenid;
		fetch('SelectCharacter', { citizenid });
	}
}

function tryAutoSelectDefaultSlot(attempt = 0) {
	if (!$('.menu-container.slots-container').is(':visible')) return;
	if ($('.slot.selected').length > 0) return;
	if (loadingSlot) {
		if (attempt < 10) setTimeout(() => tryAutoSelectDefaultSlot(attempt + 1), 120);
		return;
	}

	if (applyPreloadedDefaultSelection(true)) {
		return;
	}

	if (attempt < 12) {
		setTimeout(() => tryAutoSelectDefaultSlot(attempt + 1), 180);
	}
}

function fetch(event, data) {
	return $.post('https://origen_titlemenu/' + event, JSON.stringify(data)).promise();
}

function exportEvent(script, event, data) {
	return $.post('https://' + script + '/' + event, JSON.stringify(data)).promise();
}

function TriggerCallback(event, data) {
	data.name = event;
	return $.post(
		'https://origen_titlemenu/TriggerCallback',
		JSON.stringify(data)
	).promise();
}

function setCharacterInfo(slot) {
	debuger('INFO SLOT:', slot);
	slot = parseInt(slot);

	// Find the object in the "characters" array whose "cid" property matches the "slot" parameter:
	selectedCharacter = characters.find((character) => character.cid === slot);
	let birthdate = new Date(selectedCharacter.birthdate);
	let birthdateFormatted = selectedCharacter.birthdate
	// validar fecha
	if (!birthdate.toString().includes('Invalid')) {
		let options = { year: 'numeric', month: 'long', day: 'numeric' };
		birthdateFormatted = birthdate.toLocaleDateString('es-ES', options);
	}

	$('.info-data.birthdate').text(birthdateFormatted);
	$('.info-data.job').text(selectedCharacter.job + ' - ' + selectedCharacter.grade);
	$('.info-data.nationality').text(selectedCharacter.nationality || 'Desconocida');
	$('.info-data.bank').text(selectedCharacter.bank || '0');
	$('.player-last-session').text(resolveLastSession(selectedCharacter));
	$('.player-playtime').text(
		formatPlaytime(selectedCharacter.playtime || selectedCharacter.timePlayed || selectedCharacter.hours_played)
	);
	// $(".info-data.nationality").text(characters[slot].nationality || "Desconocida");

	setTimeout(() => {
		$('.stat.heart .stat-bar').css(
			'width',
			selectedCharacter.health - 100 + '%' || 0 + '%'
		);
		$('.stat.hunger .stat-bar').css(
			'width',
			selectedCharacter.hunger + '%' || 0 + '%'
		);
		$('.stat.thirst .stat-bar').css(
			'width',
			selectedCharacter.thirst + '%' || 0 + '%'
		);
	}, 100);

	const streakInfo = getStreakVisualData(selectedCharacter);
	$('.player-streak').text(`${streakInfo.days} DÍAS`);
	renderStreakGoalsBar(streakInfo);
}

function getStreakVisualData(character) {
	const rawStreak =
		character?.login_streak ??
		character?.loginStreak ??
		character?.streak ??
		0;

	const days = Math.max(0, parseInt(rawStreak, 10) || 0);
	const milestones = [3, 7, 14, 30];
	const nextMilestone = milestones.find((value) => days < value) || milestones[milestones.length - 1];
	const previousMilestone = milestones.reduce((acc, value) => (value < nextMilestone ? value : acc), 0);

	let progress = 100;
	if (days < nextMilestone) {
		const range = Math.max(1, nextMilestone - previousMilestone);
		const current = Math.max(0, days - previousMilestone);
		progress = Math.min(100, Math.round((current / range) * 100));
	}

	return {
		days,
		progress,
		nextMilestone,
		milestones,
		goalText: days >= 30 ? 'Meta máxima alcanzada' : `Meta ${nextMilestone} días`
	};
}

function renderStreakGoalsBar(streakInfo) {
	const milestones = streakInfo.milestones || [3, 7, 14, 30];
	const capGoal = milestones[milestones.length - 1];
	const progress = Math.max(0, Math.min(100, Math.round((streakInfo.days / capGoal) * 100)));

	$('#streak-days-main').text(streakInfo.days);
	$('#streak-track-fill').css('width', `${progress}%`);

	$('.streak-milestone').each(function () {
		const goal = parseInt($(this).attr('data-goal'), 10) || 0;
		$(this).removeClass('active completed');

		if (streakInfo.days >= goal) {
			$(this).addClass('completed');
		} else if (goal === streakInfo.nextMilestone) {
			$(this).addClass('active');
		}
	});
}

function resetMenu() {
	if (autoSelectTimeout) {
		clearTimeout(autoSelectTimeout);
		autoSelectTimeout = null;
	}
	lastSelectCharacterRequest = null;

	$('.slots-container .bottom-bar')
		.removeClass('animate__fadeOutDown')
		.addClass('animate__fadeInUp')
		.fadeIn();

	$('.menu-section').removeClass('hide').hide();
	$('.menu-container').hide();
	$('.home-screen').show();
	$('.slot').removeClass('selected');
	$('.info-pj').removeClass('show');
	$('.spawn-selector').removeClass('show').hide();
	stopRpClock();
	renderStreakGoalsBar(getStreakVisualData({ login_streak: 0 }));

	// Limpiar el sistema de bloqueo de slots
	if (slotLockTimeout) {
		clearTimeout(slotLockTimeout);
		slotLockTimeout = null;
	}
	slotSelectionLocked = false;
	$('.slot').removeClass('locked');

	// Resetear navegación
	$('.nav-link').removeClass('active');
	$('#nav-home').addClass('active');
	$('.modern-content').show();
	$('.secciones').removeClass('show').hide();

	if (localStorage.getItem('ori_vol') != null) {
		$('#progress-volumen').val(localStorage.getItem('ori_vol') * 2 * 100);
		setVolumeIcon(localStorage.getItem('ori_vol') * 2 * 100);
	} else {
		$('#progress-volumen').val(80);
		setVolumeIcon(80);
	}

	$('#progress-volumen').value;
	debuger(localStorage.getItem('ori_vol') * 2);
	s_background.currentTime = '0';
	// s_background.play();

	startStatsUpdate();
	$('.menu-container.principal').fadeIn(1000);
}

function loadSection(seccion) {
	$('.home-screen').addClass('hide2');
	setTimeout(() => {
		$('.seccion').hide();
		$('.seccion.' + seccion).show();
		$('.secciones').css('display', 'block');
		setTimeout(() => {
			$('.secciones').addClass('show');
			s_swipe.currentTime = '0';
			s_swipe.play();
		}, 500);
		$('.info-bar.top').addClass('back');
	}, 500);
}

$(document).on('click', '.info-bar .back-button', function () {
	$('.info-bar.top').removeClass('back');
	$('.secciones')
		.removeClass('show')
		.fadeOut(500, function () {
			s_swipe.currentTime = '0';
			s_swipe.play();
			$('.home-screen').removeClass('hide2');
			// Volver a HOME
			$('.nav-link').removeClass('active');
			$('#nav-home').addClass('active');
			$('.modern-content').show();
		});
});

// function sliderselector(crr) {
// 	const vol = $(crr).val();
// 	setVolumeIcon(vol);
// 	const volValue = parseInt(vol) / 100 / 2;
// 	s_background.volume = volValue;
// 	localStorage.setItem('ori_vol', volValue);
// 	const progressElement = document.getElementById('progress-volumen');
// 	progressElement.value = vol;
// }

function sliderselector(crr) {
	const vol = $(crr).val();
	setVolumeIcon(vol);
	const volValue = parseInt(vol) / 100 / 2;
	window.parent.document.getElementsByName('origen_loadingasset')[0].contentWindow.postMessage({ action: "changeVolume", volume: volValue }, "*");
	// s_background.volume = volValue;
	localStorage.setItem("ori_vol", volValue);
	const progressElement = document.getElementById("progress-volumen");
	progressElement.value = vol;
}

function setVolumeIcon(volume) {
	let iconClass = '';
	if (volume <= 1) {
		iconClass = 'fa-volume-xmark';
	} else if (volume < 33) {
		iconClass = 'fa-volume-off';
	} else if (volume < 66) {
		iconClass = 'fa-volume-low';
	} else {
		iconClass = 'fa-volume-high';
	}
	$('.volume-icon i')
		.removeClass()
		.addClass('fas ' + iconClass);
}

function loadSpawnSelector() {
	btnSpawnLocation = false;
	btnSpawnLocationFirst = false;
	fetch('StartSpawnCamera', {});
	renderSpawnOverview();
	$('.slots-container .spawn-selector').fadeIn(300, function () {
		setTimeout(() => {
			$(this).addClass('show');
		}, 300);
		cargarMapaCentral();
		fetch('HudFadeIn', { time: 420 });
	});
}

function formatPlaytime(value) {
	const minutes = Number(value);
	if (!minutes || Number.isNaN(minutes)) return 'No disponible';
	const h = Math.floor(minutes / 60);
	const m = minutes % 60;
	return `${h}h ${m}m`;
}

function resolveLastSession(character) {
	if (!character) return 'No disponible';

	const raw =
		character.last_session ||
		character.last_login ||
		character.last_seen ||
		character.lastLoggedOutUnix ||
		character.last_logged_out ||
		character.updated_at ||
		character.lastPlayed ||
		character.last_played;

	if (!raw) return 'No disponible';

	let normalized = raw;
	if (typeof raw === 'number') {
		normalized = raw < 1000000000000 ? raw * 1000 : raw;
	} else if (typeof raw === 'string' && /^\d+$/.test(raw)) {
		const numeric = Number(raw);
		normalized = numeric < 1000000000000 ? numeric * 1000 : numeric;
	}

	const date = new Date(normalized);
	if (Number.isNaN(date.getTime())) return String(raw);

	return date.toLocaleString('es-ES', {
		day: '2-digit',
		month: '2-digit',
		year: '2-digit',
		hour: '2-digit',
		minute: '2-digit'
	});
}

function resolveWeatherLabel(spawnData) {
	const weather =
		spawnData?.weather ||
		spawnData?.currentWeather ||
		spawnData?.serverWeather ||
		spawnData?.meta?.weather;

	return weather ? String(weather).toUpperCase() : 'No disponible';
}

function startRpClock(serverTime = null) {
	if (rpClockInterval) clearInterval(rpClockInterval);

	let hour = Number(serverTime?.hour);
	let minute = Number(serverTime?.minute);
	let useServerClock = !Number.isNaN(hour) && !Number.isNaN(minute);

	if (useServerClock) {
		hour = ((hour % 24) + 24) % 24;
		minute = ((minute % 60) + 60) % 60;
	}

	const updateClock = () => {
		if (useServerClock) {
			const hh = String(hour).padStart(2, '0');
			const mm = String(minute).padStart(2, '0');
			$('#overview-rp-time').text(`${hh}:${mm}`);

			minute += 1;
			if (minute >= 60) {
				minute = 0;
				hour = (hour + 1) % 24;
			}
			return;
		}

		const now = new Date();
		$('#overview-rp-time').text(now.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }));
	};

	updateClock();
	rpClockInterval = setInterval(updateClock, useServerClock ? 60000 : 1000);
}

function stopRpClock() {
	if (rpClockInterval) {
		clearInterval(rpClockInterval);
		rpClockInterval = null;
	}
}

function renderSpawnOverview(spawnData = null) {
	$('#overview-weather').text(resolveWeatherLabel(spawnData));
	$('#overview-latency').text(($('#server-latency').text() || '-- MS').trim() || '-- MS');
	$('#overview-version').text(($('#server-version').text() || '--').trim() || '--');
	$('#spawn-server-online').text(($('#players-online').text() || '--/--').trim() || '--/--');
	$('#spawn-server-staff').text(($('#staff-online').text() || '--').trim() || '--');
	$('#spawn-server-latency').text(($('#server-latency').text() || '-- MS').trim() || '-- MS');
	$('#spawn-server-uptime').text(($('#server-uptime').text() || '--').trim() || '--');

	startRpClock(spawnData?.serverTime);
}

window.renderSpawnOverview = renderSpawnOverview;

$(document).on('click', '.link', function () {
	const url = $(this).attr('url');
	if (url) {
		window.invokeNative('openUrl', url);
	}
});

s_background.addEventListener('ended', function () {
	s_background.currentTime = 0;
	// s_background.play();
});


function sendIframeMessage(iframeId, type, payload = {}, targetOrigin = "*") {
	const iframe = parent.document.getElementById(iframeId);
	if (!iframe) {
		console.warn(`Iframe "${iframeId}" is not present in the DOM`);
		return;
	}
	const message = { type, ...payload };
	if (iframe.contentWindow) {
		iframe.contentWindow.postMessage(message, targetOrigin);
	}
}

const pressedMenuComboKeys = {};
let menuComboActive = false;

function toggleTitleMenuIntroMusic() {
	try {
		const marco = window.parent.document.getElementsByName('origen_loadingasset')[0];
		if (marco && marco.contentWindow) {
			marco.contentWindow.postMessage({ action: 'toggleMusic' }, '*');
		}
	} catch (e) {
		console.error('[origen_titlemenu] Error al alternar musica: ' + e.message);
	}
	try {
		sendIframeMessage('music-frame', 'toggleMusic');
	} catch (e) {}
}

window.addEventListener('keydown', function (e) {
	const key = e.key ? e.key.toLowerCase() : '';
	const code = e.code || '';
	if (code) pressedMenuComboKeys[code] = true;
	if (key) pressedMenuComboKeys[key] = true;

	const isQ = pressedMenuComboKeys['KeyQ'] || pressedMenuComboKeys['q'];
	const isR = pressedMenuComboKeys['KeyR'] || pressedMenuComboKeys['r'];

	if (isQ && isR) {
		if (!menuComboActive) {
			menuComboActive = true;
			toggleTitleMenuIntroMusic();
		}
	}
});

window.addEventListener('keyup', function (e) {
	const key = e.key ? e.key.toLowerCase() : '';
	const code = e.code || '';
	if (code) delete pressedMenuComboKeys[code];
	if (key) delete pressedMenuComboKeys[key];

	const isQ = pressedMenuComboKeys['KeyQ'] || pressedMenuComboKeys['q'];
	const isR = pressedMenuComboKeys['KeyR'] || pressedMenuComboKeys['r'];
	if (!isQ || !isR) {
		menuComboActive = false;
	}
});

window.addEventListener('blur', function () {
	for (const k in pressedMenuComboKeys) delete pressedMenuComboKeys[k];
	menuComboActive = false;
});