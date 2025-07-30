/* Base margin utilities */
@utility m-safe {
	margin-top: env(safe-area-inset-top);
	margin-right: env(safe-area-inset-right);
	margin-bottom: env(safe-area-inset-bottom);
	margin-left: env(safe-area-inset-left);
}
@utility -m-safe {
	margin-top: calc(env(safe-area-inset-top) * -1);
	margin-right: calc(env(safe-area-inset-right) * -1);
	margin-bottom: calc(env(safe-area-inset-bottom) * -1);
	margin-left: calc(env(safe-area-inset-left) * -1);
}
@utility mx-safe {
	margin-right: env(safe-area-inset-right);
	margin-left: env(safe-area-inset-left);
}
@utility -mx-safe {
	margin-right: calc(env(safe-area-inset-right) * -1);
	margin-left: calc(env(safe-area-inset-left) * -1);
}
@utility my-safe {
	margin-top: env(safe-area-inset-top);
	margin-bottom: env(safe-area-inset-bottom);
}
@utility -my-safe {
	margin-top: calc(env(safe-area-inset-top) * -1);
	margin-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility ms-safe {
	margin-inline-start: env(safe-area-inset-left);
}
@utility -ms-safe {
	margin-inline-start: calc(env(safe-area-inset-left) * -1);
}
@utility me-safe {
	margin-inline-end: env(safe-area-inset-right);
}
@utility -me-safe {
	margin-inline-end: calc(env(safe-area-inset-right) * -1);
}
@utility mt-safe {
	margin-top: env(safe-area-inset-top);
}
@utility -mt-safe {
	margin-top: calc(env(safe-area-inset-top) * -1);
}
@utility mr-safe {
	margin-right: env(safe-area-inset-right);
}
@utility -mr-safe {
	margin-right: calc(env(safe-area-inset-right) * -1);
}
@utility mb-safe {
	margin-bottom: env(safe-area-inset-bottom);
}
@utility -mb-safe {
	margin-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility ml-safe {
	margin-left: env(safe-area-inset-left);
}
@utility -ml-safe {
	margin-left: calc(env(safe-area-inset-left) * -1);
}

/* Base padding utilities */
@utility p-safe {
	padding-top: env(safe-area-inset-top);
	padding-right: env(safe-area-inset-right);
	padding-bottom: env(safe-area-inset-bottom);
	padding-left: env(safe-area-inset-left);
}
@utility -p-safe {
	padding-top: calc(env(safe-area-inset-top) * -1);
	padding-right: calc(env(safe-area-inset-right) * -1);
	padding-bottom: calc(env(safe-area-inset-bottom) * -1);
	padding-left: calc(env(safe-area-inset-left) * -1);
}
@utility px-safe {
	padding-right: env(safe-area-inset-right);
	padding-left: env(safe-area-inset-left);
}
@utility -px-safe {
	padding-right: calc(env(safe-area-inset-right) * -1);
	padding-left: calc(env(safe-area-inset-left) * -1);
}
@utility py-safe {
	padding-top: env(safe-area-inset-top);
	padding-bottom: env(safe-area-inset-bottom);
}
@utility -py-safe {
	padding-top: calc(env(safe-area-inset-top) * -1);
	padding-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility ps-safe {
	padding-inline-start: env(safe-area-inset-left);
}
@utility -ps-safe {
	padding-inline-start: calc(env(safe-area-inset-left) * -1);
}
@utility pe-safe {
	padding-inline-end: env(safe-area-inset-right);
}
@utility -pe-safe {
	padding-inline-end: calc(env(safe-area-inset-right) * -1);
}
@utility pt-safe {
	padding-top: env(safe-area-inset-top);
}
@utility -pt-safe {
	padding-top: calc(env(safe-area-inset-top) * -1);
}
@utility pr-safe {
	padding-right: env(safe-area-inset-right);
}
@utility -pr-safe {
	padding-right: calc(env(safe-area-inset-right) * -1);
}
@utility pb-safe {
	padding-bottom: env(safe-area-inset-bottom);
}
@utility -pb-safe {
	padding-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility pl-safe {
	padding-left: env(safe-area-inset-left);
}
@utility -pl-safe {
	padding-left: calc(env(safe-area-inset-left) * -1);
}

/* Scroll margin utilities */
@utility scroll-m-safe {
	scroll-margin-top: env(safe-area-inset-top);
	scroll-margin-right: env(safe-area-inset-right);
	scroll-margin-bottom: env(safe-area-inset-bottom);
	scroll-margin-left: env(safe-area-inset-left);
}
@utility -scroll-m-safe {
	scroll-margin-top: calc(env(safe-area-inset-top) * -1);
	scroll-margin-right: calc(env(safe-area-inset-right) * -1);
	scroll-margin-bottom: calc(env(safe-area-inset-bottom) * -1);
	scroll-margin-left: calc(env(safe-area-inset-left) * -1);
}
@utility scroll-mx-safe {
	scroll-margin-right: env(safe-area-inset-right);
	scroll-margin-left: env(safe-area-inset-left);
}
@utility -scroll-mx-safe {
	scroll-margin-right: calc(env(safe-area-inset-right) * -1);
	scroll-margin-left: calc(env(safe-area-inset-left) * -1);
}
@utility scroll-my-safe {
	scroll-margin-top: env(safe-area-inset-top);
	scroll-margin-bottom: env(safe-area-inset-bottom);
}
@utility -scroll-my-safe {
	scroll-margin-top: calc(env(safe-area-inset-top) * -1);
	scroll-margin-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility scroll-ms-safe {
	scroll-margin-inline-start: env(safe-area-inset-left);
}
@utility -scroll-ms-safe {
	scroll-margin-inline-start: calc(env(safe-area-inset-left) * -1);
}
@utility scroll-me-safe {
	scroll-margin-inline-end: env(safe-area-inset-right);
}
@utility -scroll-me-safe {
	scroll-margin-inline-end: calc(env(safe-area-inset-right) * -1);
}
@utility scroll-mt-safe {
	scroll-margin-top: env(safe-area-inset-top);
}
@utility -scroll-mt-safe {
	scroll-margin-top: calc(env(safe-area-inset-top) * -1);
}
@utility scroll-mr-safe {
	scroll-margin-right: env(safe-area-inset-right);
}
@utility -scroll-mr-safe {
	scroll-margin-right: calc(env(safe-area-inset-right) * -1);
}
@utility scroll-mb-safe {
	scroll-margin-bottom: env(safe-area-inset-bottom);
}
@utility -scroll-mb-safe {
	scroll-margin-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility scroll-ml-safe {
	scroll-margin-left: env(safe-area-inset-left);
}
@utility -scroll-ml-safe {
	scroll-margin-left: calc(env(safe-area-inset-left) * -1);
}

/* Scroll padding utilities */
@utility scroll-p-safe {
	scroll-padding-top: env(safe-area-inset-top);
	scroll-padding-right: env(safe-area-inset-right);
	scroll-padding-bottom: env(safe-area-inset-bottom);
	scroll-padding-left: env(safe-area-inset-left);
}
@utility -scroll-p-safe {
	scroll-padding-top: calc(env(safe-area-inset-top) * -1);
	scroll-padding-right: calc(env(safe-area-inset-right) * -1);
	scroll-padding-bottom: calc(env(safe-area-inset-bottom) * -1);
	scroll-padding-left: calc(env(safe-area-inset-left) * -1);
}
@utility scroll-px-safe {
	scroll-padding-right: env(safe-area-inset-right);
	scroll-padding-left: env(safe-area-inset-left);
}
@utility -scroll-px-safe {
	scroll-padding-right: calc(env(safe-area-inset-right) * -1);
	scroll-padding-left: calc(env(safe-area-inset-left) * -1);
}
@utility scroll-py-safe {
	scroll-padding-top: env(safe-area-inset-top);
	scroll-padding-bottom: env(safe-area-inset-bottom);
}
@utility -scroll-py-safe {
	scroll-padding-top: calc(env(safe-area-inset-top) * -1);
	scroll-padding-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility scroll-ps-safe {
	scroll-padding-inline-start: env(safe-area-inset-left);
}
@utility -scroll-ps-safe {
	scroll-padding-inline-start: calc(env(safe-area-inset-left) * -1);
}
@utility scroll-pe-safe {
	scroll-padding-inline-end: env(safe-area-inset-right);
}
@utility -scroll-pe-safe {
	scroll-padding-inline-end: calc(env(safe-area-inset-right) * -1);
}
@utility scroll-pt-safe {
	scroll-padding-top: env(safe-area-inset-top);
}
@utility -scroll-pt-safe {
	scroll-padding-top: calc(env(safe-area-inset-top) * -1);
}
@utility scroll-pr-safe {
	scroll-padding-right: env(safe-area-inset-right);
}
@utility -scroll-pr-safe {
	scroll-padding-right: calc(env(safe-area-inset-right) * -1);
}
@utility scroll-pb-safe {
	scroll-padding-bottom: env(safe-area-inset-bottom);
}
@utility -scroll-pb-safe {
	scroll-padding-bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility scroll-pl-safe {
	scroll-padding-left: env(safe-area-inset-left);
}
@utility -scroll-pl-safe {
	scroll-padding-left: calc(env(safe-area-inset-left) * -1);
}

/* Inset utilities */
@utility inset-safe {
	top: env(safe-area-inset-top);
	right: env(safe-area-inset-right);
	bottom: env(safe-area-inset-bottom);
	left: env(safe-area-inset-left);
}
@utility -inset-safe {
	top: calc(env(safe-area-inset-top) * -1);
	right: calc(env(safe-area-inset-right) * -1);
	bottom: calc(env(safe-area-inset-bottom) * -1);
	left: calc(env(safe-area-inset-left) * -1);
}
@utility inset-x-safe {
	right: env(safe-area-inset-right);
	left: env(safe-area-inset-left);
}
@utility -inset-x-safe {
	right: calc(env(safe-area-inset-right) * -1);
	left: calc(env(safe-area-inset-left) * -1);
}
@utility inset-y-safe {
	top: env(safe-area-inset-top);
	bottom: env(safe-area-inset-bottom);
}
@utility -inset-y-safe {
	top: calc(env(safe-area-inset-top) * -1);
	bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility start-safe {
	inset-inline-start: env(safe-area-inset-left);
}
@utility -start-safe {
	inset-inline-start: calc(env(safe-area-inset-left) * -1);
}
@utility end-safe {
	inset-inline-end: env(safe-area-inset-right);
}
@utility -end-safe {
	inset-inline-end: calc(env(safe-area-inset-right) * -1);
}
@utility top-safe {
	top: env(safe-area-inset-top);
}
@utility -top-safe {
	top: calc(env(safe-area-inset-top) * -1);
}
@utility right-safe {
	right: env(safe-area-inset-right);
}
@utility -right-safe {
	right: calc(env(safe-area-inset-right) * -1);
}
@utility bottom-safe {
	bottom: env(safe-area-inset-bottom);
}
@utility -bottom-safe {
	bottom: calc(env(safe-area-inset-bottom) * -1);
}
@utility left-safe {
	left: env(safe-area-inset-left);
}
@utility -left-safe {
	left: calc(env(safe-area-inset-left) * -1);
}

/* Height utilities */
@utility h-screen-safe {
	height: calc(
		100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
	height: -webkit-fill-available;
}
@utility max-h-screen-safe {
	max-height: calc(
		100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
	max-height: -webkit-fill-available;
}
@utility min-h-screen-safe {
	min-height: calc(
		100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
	min-height: -webkit-fill-available;
}
@utility h-fill-safe {
	height: -webkit-fill-available;
}
@utility max-h-fill-safe {
	max-height: -webkit-fill-available;
}
@utility min-h-fill-safe {
	min-height: -webkit-fill-available;
}
@utility h-vh-safe {
	height: calc(
		100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility max-h-vh-safe {
	max-height: calc(
		100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility min-h-vh-safe {
	min-height: calc(
		100vh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility h-dvh-safe {
	height: calc(
		100dvh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility max-h-dvh-safe {
	max-height: calc(
		100dvh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility min-h-dvh-safe {
	min-height: calc(
		100dvh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility h-svh-safe {
	height: calc(
		100svh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility max-h-svh-safe {
	max-height: calc(
		100svh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility min-h-svh-safe {
	min-height: calc(
		100svh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility h-lvh-safe {
	height: calc(
		100lvh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility max-h-lvh-safe {
	max-height: calc(
		100lvh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}
@utility min-h-lvh-safe {
	min-height: calc(
		100lvh - (env(safe-area-inset-top) + env(safe-area-inset-bottom))
	);
}

/* Margin utilities with offset variant */
@utility m-safe-offset-* {
	margin-top: --spacing(--value(integer, [integer]) + env(safe-area-inset-top));
	margin-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	margin-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
	margin-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -m-safe-offset-* {
	margin-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	margin-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	margin-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
	margin-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility mx-safe-offset-* {
	margin-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	margin-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -mx-safe-offset-* {
	margin-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	margin-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility my-safe-offset-* {
	margin-top: --spacing(--value(integer, [integer]) + env(safe-area-inset-top));
	margin-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -my-safe-offset-* {
	margin-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	margin-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility ms-safe-offset-* {
	margin-inline-start: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -ms-safe-offset-* {
	margin-inline-start: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility me-safe-offset-* {
	margin-inline-end: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -me-safe-offset-* {
	margin-inline-end: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility mt-safe-offset-* {
	margin-top: --spacing(--value(integer, [integer]) + env(safe-area-inset-top));
}
@utility -mt-safe-offset-* {
	margin-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
}
@utility mr-safe-offset-* {
	margin-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -mr-safe-offset-* {
	margin-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility mb-safe-offset-* {
	margin-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -mb-safe-offset-* {
	margin-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility ml-safe-offset-* {
	margin-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -ml-safe-offset-* {
	margin-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}

/* Margin utilities with or variant */
@utility m-safe-or-* {
	margin-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	margin-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	margin-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
	margin-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -m-safe-or-* {
	margin-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	margin-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	margin-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	margin-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility mx-safe-or-* {
	margin-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	margin-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -mx-safe-or-* {
	margin-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	margin-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility my-safe-or-* {
	margin-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	margin-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -my-safe-or-* {
	margin-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	margin-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility ms-safe-or-* {
	margin-inline-start: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -ms-safe-or-* {
	margin-inline-start: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility me-safe-or-* {
	margin-inline-end: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -me-safe-or-* {
	margin-inline-end: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility mt-safe-or-* {
	margin-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
}
@utility -mt-safe-or-* {
	margin-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility mr-safe-or-* {
	margin-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -mr-safe-or-* {
	margin-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility mb-safe-or-* {
	margin-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -mb-safe-or-* {
	margin-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility ml-safe-or-* {
	margin-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -ml-safe-or-* {
	margin-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}

/* Padding utilities with offset variant */
@utility p-safe-offset-* {
	padding-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
	padding-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	padding-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
	padding-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -p-safe-offset-* {
	padding-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	padding-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	padding-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
	padding-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility px-safe-offset-* {
	padding-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	padding-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -px-safe-offset-* {
	padding-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	padding-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility py-safe-offset-* {
	padding-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
	padding-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -py-safe-offset-* {
	padding-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	padding-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility ps-safe-offset-* {
	padding-inline-start: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -ps-safe-offset-* {
	padding-inline-start: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility pe-safe-offset-* {
	padding-inline-end: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -pe-safe-offset-* {
	padding-inline-end: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility pt-safe-offset-* {
	padding-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
}
@utility -pt-safe-offset-* {
	padding-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
}
@utility pr-safe-offset-* {
	padding-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -pr-safe-offset-* {
	padding-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility pb-safe-offset-* {
	padding-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -pb-safe-offset-* {
	padding-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility pl-safe-offset-* {
	padding-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -pl-safe-offset-* {
	padding-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}

/* Padding utilities with or variant */
@utility p-safe-or-* {
	padding-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	padding-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	padding-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
	padding-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -p-safe-or-* {
	padding-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	padding-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	padding-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	padding-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility px-safe-or-* {
	padding-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	padding-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -px-safe-or-* {
	padding-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	padding-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility py-safe-or-* {
	padding-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	padding-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -py-safe-or-* {
	padding-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	padding-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility ps-safe-or-* {
	padding-inline-start: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -ps-safe-or-* {
	padding-inline-start: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility pe-safe-or-* {
	padding-inline-end: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -pe-safe-or-* {
	padding-inline-end: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility pt-safe-or-* {
	padding-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
}
@utility -pt-safe-or-* {
	padding-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility pr-safe-or-* {
	padding-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -pr-safe-or-* {
	padding-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility pb-safe-or-* {
	padding-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -pb-safe-or-* {
	padding-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility pl-safe-or-* {
	padding-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -pl-safe-or-* {
	padding-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}

/* Scroll margin utilities with offset variant */
@utility scroll-m-safe-offset-* {
	scroll-margin-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
	scroll-margin-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	scroll-margin-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
	scroll-margin-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-m-safe-offset-* {
	scroll-margin-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	scroll-margin-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	scroll-margin-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
	scroll-margin-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility scroll-mx-safe-offset-* {
	scroll-margin-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	scroll-margin-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-mx-safe-offset-* {
	scroll-margin-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	scroll-margin-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility scroll-my-safe-offset-* {
	scroll-margin-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
	scroll-margin-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -scroll-my-safe-offset-* {
	scroll-margin-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	scroll-margin-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility scroll-ms-safe-offset-* {
	scroll-margin-inline-start: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-ms-safe-offset-* {
	scroll-margin-inline-start: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility scroll-me-safe-offset-* {
	scroll-margin-inline-end: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -scroll-me-safe-offset-* {
	scroll-margin-inline-end: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility scroll-mt-safe-offset-* {
	scroll-margin-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
}
@utility -scroll-mt-safe-offset-* {
	scroll-margin-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
}
@utility scroll-mr-safe-offset-* {
	scroll-margin-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -scroll-mr-safe-offset-* {
	scroll-margin-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility scroll-mb-safe-offset-* {
	scroll-margin-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -scroll-mb-safe-offset-* {
	scroll-margin-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility scroll-ml-safe-offset-* {
	scroll-margin-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-ml-safe-offset-* {
	scroll-margin-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}

/* Scroll margin utilities with or variant */
@utility scroll-m-safe-or-* {
	scroll-margin-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	scroll-margin-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	scroll-margin-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
	scroll-margin-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-m-safe-or-* {
	scroll-margin-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-margin-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-margin-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-margin-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-mx-safe-or-* {
	scroll-margin-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	scroll-margin-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-mx-safe-or-* {
	scroll-margin-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-margin-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-my-safe-or-* {
	scroll-margin-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	scroll-margin-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-my-safe-or-* {
	scroll-margin-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-margin-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-ms-safe-or-* {
	scroll-margin-inline-start: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-ms-safe-or-* {
	scroll-margin-inline-start: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-me-safe-or-* {
	scroll-margin-inline-end: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-me-safe-or-* {
	scroll-margin-inline-end: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-mt-safe-or-* {
	scroll-margin-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-mt-safe-or-* {
	scroll-margin-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-mr-safe-or-* {
	scroll-margin-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-mr-safe-or-* {
	scroll-margin-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-mb-safe-or-* {
	scroll-margin-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-mb-safe-or-* {
	scroll-margin-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-ml-safe-or-* {
	scroll-margin-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-ml-safe-or-* {
	scroll-margin-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}

/* Scroll padding utilities with offset variant */
@utility scroll-p-safe-offset-* {
	scroll-padding-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
	scroll-padding-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	scroll-padding-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
	scroll-padding-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-p-safe-offset-* {
	scroll-padding-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	scroll-padding-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	scroll-padding-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
	scroll-padding-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility scroll-px-safe-offset-* {
	scroll-padding-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
	scroll-padding-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-px-safe-offset-* {
	scroll-padding-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	scroll-padding-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility scroll-py-safe-offset-* {
	scroll-padding-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
	scroll-padding-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -scroll-py-safe-offset-* {
	scroll-padding-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	scroll-padding-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility scroll-ps-safe-offset-* {
	scroll-padding-inline-start: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-ps-safe-offset-* {
	scroll-padding-inline-start: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility scroll-pe-safe-offset-* {
	scroll-padding-inline-end: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -scroll-pe-safe-offset-* {
	scroll-padding-inline-end: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility scroll-pt-safe-offset-* {
	scroll-padding-top: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-top)
	);
}
@utility -scroll-pt-safe-offset-* {
	scroll-padding-top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
}
@utility scroll-pr-safe-offset-* {
	scroll-padding-right: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -scroll-pr-safe-offset-* {
	scroll-padding-right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility scroll-pb-safe-offset-* {
	scroll-padding-bottom: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-bottom)
	);
}
@utility -scroll-pb-safe-offset-* {
	scroll-padding-bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility scroll-pl-safe-offset-* {
	scroll-padding-left: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -scroll-pl-safe-offset-* {
	scroll-padding-left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}

/* Scroll padding utilities with or variant */
@utility scroll-p-safe-or-* {
	scroll-padding-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	scroll-padding-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	scroll-padding-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
	scroll-padding-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-p-safe-or-* {
	scroll-padding-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-padding-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-padding-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-padding-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-px-safe-or-* {
	scroll-padding-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	scroll-padding-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-px-safe-or-* {
	scroll-padding-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-padding-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-py-safe-or-* {
	scroll-padding-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
	scroll-padding-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-py-safe-or-* {
	scroll-padding-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	scroll-padding-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-ps-safe-or-* {
	scroll-padding-inline-start: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-ps-safe-or-* {
	scroll-padding-inline-start: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-pe-safe-or-* {
	scroll-padding-inline-end: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-pe-safe-or-* {
	scroll-padding-inline-end: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-pt-safe-or-* {
	scroll-padding-top: max(
		env(safe-area-inset-top),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-pt-safe-or-* {
	scroll-padding-top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-pr-safe-or-* {
	scroll-padding-right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-pr-safe-or-* {
	scroll-padding-right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-pb-safe-or-* {
	scroll-padding-bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-pb-safe-or-* {
	scroll-padding-bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility scroll-pl-safe-or-* {
	scroll-padding-left: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -scroll-pl-safe-or-* {
	scroll-padding-left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}

/* Inset utilities with offset variant */
@utility inset-safe-offset-* {
	top: --spacing(--value(integer, [integer]) + env(safe-area-inset-top));
	right: --spacing(--value(integer, [integer]) + env(safe-area-inset-right));
	bottom: --spacing(--value(integer, [integer]) + env(safe-area-inset-bottom));
	left: --spacing(--value(integer, [integer]) + env(safe-area-inset-left));
}
@utility -inset-safe-offset-* {
	top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
	left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility inset-x-safe-offset-* {
	right: --spacing(--value(integer, [integer]) + env(safe-area-inset-right));
	left: --spacing(--value(integer, [integer]) + env(safe-area-inset-left));
}
@utility -inset-x-safe-offset-* {
	right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
	left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility inset-y-safe-offset-* {
	top: --spacing(--value(integer, [integer]) + env(safe-area-inset-top));
	bottom: --spacing(--value(integer, [integer]) + env(safe-area-inset-bottom));
}
@utility -inset-y-safe-offset-* {
	top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
	bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility start-safe-offset-* {
	inset-inline-start: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-left)
	);
}
@utility -start-safe-offset-* {
	inset-inline-start: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}
@utility end-safe-offset-* {
	inset-inline-end: --spacing(
		--value(integer, [integer]) + env(safe-area-inset-right)
	);
}
@utility -end-safe-offset-* {
	inset-inline-end: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility top-safe-offset-* {
	top: --spacing(--value(integer, [integer]) + env(safe-area-inset-top));
}
@utility -top-safe-offset-* {
	top: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-top) * -1
	);
}
@utility right-safe-offset-* {
	right: --spacing(--value(integer, [integer]) + env(safe-area-inset-right));
}
@utility -right-safe-offset-* {
	right: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-right) * -1
	);
}
@utility bottom-safe-offset-* {
	bottom: --spacing(--value(integer, [integer]) + env(safe-area-inset-bottom));
}
@utility -bottom-safe-offset-* {
	bottom: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-bottom) * -1
	);
}
@utility left-safe-offset-* {
	left: --spacing(--value(integer, [integer]) + env(safe-area-inset-left));
}
@utility -left-safe-offset-* {
	left: --spacing(
		--value(integer, [integer]) * -1 + env(safe-area-inset-left) * -1
	);
}

/* Inset utilities with or variant */
@utility inset-safe-or-* {
	top: max(env(safe-area-inset-top), --spacing(--value(integer, [integer])));
	right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
	left: max(env(safe-area-inset-left), --spacing(--value(integer, [integer])));
}
@utility -inset-safe-or-* {
	top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility inset-x-safe-or-* {
	right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
	left: max(env(safe-area-inset-left), --spacing(--value(integer, [integer])));
}
@utility -inset-x-safe-or-* {
	right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility inset-y-safe-or-* {
	top: max(env(safe-area-inset-top), --spacing(--value(integer, [integer])));
	bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -inset-y-safe-or-* {
	top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
	bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility start-safe-or-* {
	inset-inline-start: max(
		env(safe-area-inset-left),
		--spacing(--value(integer, [integer]))
	);
}
@utility -start-safe-or-* {
	inset-inline-start: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility end-safe-or-* {
	inset-inline-end: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -end-safe-or-* {
	inset-inline-end: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility top-safe-or-* {
	top: max(env(safe-area-inset-top), --spacing(--value(integer, [integer])));
}
@utility -top-safe-or-* {
	top: min(
		calc(env(safe-area-inset-top) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility right-safe-or-* {
	right: max(
		env(safe-area-inset-right),
		--spacing(--value(integer, [integer]))
	);
}
@utility -right-safe-or-* {
	right: min(
		calc(env(safe-area-inset-right) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility bottom-safe-or-* {
	bottom: max(
		env(safe-area-inset-bottom),
		--spacing(--value(integer, [integer]))
	);
}
@utility -bottom-safe-or-* {
	bottom: min(
		calc(env(safe-area-inset-bottom) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
@utility left-safe-or-* {
	left: max(env(safe-area-inset-left), --spacing(--value(integer, [integer])));
}
@utility -left-safe-or-* {
	left: min(
		calc(env(safe-area-inset-left) * -1),
		calc(--spacing(--value(integer, [integer])) * -1)
	);
}
