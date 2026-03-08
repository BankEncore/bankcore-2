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
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
    require('daisyui'),
  ],
  daisyui: {
    themes: [
      {
        bankcore: {
          primary: '#1e3a8a',
          'primary-content': '#ffffff',
          secondary: '#115e59',
          'secondary-content': '#ffffff',
          accent: '#0f766e',
          'accent-content': '#ffffff',
          neutral: '#1e293b',
          'neutral-content': '#ffffff',
          'base-100': '#f8fafc',
          'base-200': '#f1f5f9',
          'base-300': '#e2e8f0',
          'base-content': '#1e293b',
          info: '#1e3a8a',
          'info-content': '#ffffff',
          success: '#0f766e',
          'success-content': '#ffffff',
          warning: '#d4a017',
          'warning-content': '#1e293b',
          error: '#dc2626',
          'error-content': '#ffffff',
        },
      },
    ],
    defaultTheme: 'bankcore',
  },
}
