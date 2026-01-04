// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"
import "./smooth_scroll"
import "./scroll_animations"

// Cropper.js - グローバルに公開
import Cropper from "cropperjs"
window.Cropper = Cropper
