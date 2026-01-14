// Import and register all your controllers
import { application } from "./application"
import ConfirmDialogController from "./confirm_dialog_controller"
import ContactFormController from "./contact_form_controller"
import MyStoryFormController from "./my_story_form_controller"
import ImageUploadController from "./image_upload_controller"
import MediaLibraryController from "./media_library_controller"
import MediaUploadController from "./media_upload_controller"
import MediaEditorController from "./media_editor_controller"
import ThumbnailEditorController from "./thumbnail_editor_controller"
import ContentImageEditorController from "./content_image_editor_controller"
import AiAssistantController from "./ai_assistant_controller"

application.register("confirm-dialog", ConfirmDialogController)
application.register("contact-form", ContactFormController)
application.register("my-story-form", MyStoryFormController)
application.register("image-upload", ImageUploadController)
application.register("media-library", MediaLibraryController)
application.register("media-upload", MediaUploadController)
application.register("media-editor", MediaEditorController)
application.register("thumbnail-editor", ThumbnailEditorController)
application.register("content-image-editor", ContentImageEditorController)
application.register("ai-assistant", AiAssistantController)
