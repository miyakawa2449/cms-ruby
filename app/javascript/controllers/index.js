// Import and register all your controllers
import { application } from "./application"
import ConfirmDialogController from "./confirm_dialog_controller"
import ContactFormController from "./contact_form_controller"

application.register("confirm-dialog", ConfirmDialogController)
application.register("contact-form", ContactFormController)
