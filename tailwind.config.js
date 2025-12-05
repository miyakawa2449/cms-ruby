/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    container: {
      center: true,
      padding: '1.5rem',
    },
    extend: {
      colors: {
        primary: '#1E40AF',
        secondary: '#334155',
        accent: '#FCD34D'
      },
      spacing: {
        '18': '4.5rem',
        '20': '5rem',
        '96': '24rem',
        '128': '32rem',
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
  ]
}