const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'gray': {
          50: '#f9f9f9',
          100: '#ececec',
          200: '#cdcdcd',
          300: '#b4b4b4',
          400: '#9b9b9b',
          500: '#676767',
          600: '#424242',
          700: '#2f2f2f',
          800: '#212121',
          900: '#171717',
          950: '#0d0d0d',
        },
        'brand': {
          'blue': '#2f5ff2',
        }
      },
      scale: {
        '96': '0.96',
        '97': '0.97',
        '98': '0.98',
        '99': '0.99',
      },
      strokeWidth: {
        '3': '3px',
        '4': '4px',
      },
    },
  },

  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
