module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#1E40AF',
        secondary: '#334155',
        accent: '#FCD34D'
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
  ]
}