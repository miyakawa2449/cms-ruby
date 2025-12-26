// Import and register all your controllers
import { application } from "./application"
import ConfirmDialogController from "./confirm_dialog_controller"
import ContactFormController from "./contact_form_controller"
import MyStoryFormController from "./my_story_form_controller"
import ImageUploadController from "./image_upload_controller"

application.register("confirm-dialog", ConfirmDialogController)
application.register("contact-form", ContactFormController)
application.register("my-story-form", MyStoryFormController)
application.register("image-upload", ImageUploadController)
