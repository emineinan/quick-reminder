import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from '../common/utils/Logger';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import DatabaseManager from '../common/utils/DatabaseManager';
import VibrationManager from '../common/utils/VibrationManager';

@Entry
@Component
struct Index {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State reminderId: number = -1;
  @State reminderStatus: string | Resource = '';
  @State reminderTitle: string = '';
  @State reminderContent: string = '';
  @State reminderTime: string = '';
  @State showInputForm: boolean = false;
  @State notificationId: number = 1000;

  async aboutToAppear() {
    this.openNotificationPermission(this.context);
    await DatabaseManager.init(this.context);

    const savedReminderId = await DatabaseManager.getSetting('lastReminderId');
    if (savedReminderId) {
      this.reminderId = parseInt(savedReminderId);
    }

    const savedNotificationId = await DatabaseManager.getSetting('lastNotificationId');
    if (savedNotificationId) {
      this.notificationId = parseInt(savedNotificationId);
    }
  }

  build() {
    Column() {
      Stack() {
        Scroll() {
          Column() {
            Text($r('app.string.title_text'))
              .fontSize($r('app.float.title_text_font_size'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.title_text'))
              .margin({ bottom: $r('app.float.title_margin_bottom'), top: $r('app.float.page_padding') })

            if (this.showInputForm) {
              this.addForm()
            } else {
              this.mainDashboard()
            }

            if (this.reminderStatus !== '') {
              Text(this.reminderStatus)
                .fontSize($r('app.float.small_text_font_size'))
                .fontColor($r('app.color.status_text'))
                .margin({ top: $r('app.float.status_text_margin_top') })
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .padding({
            bottom: $r('app.float.page_padding'),
            left: '10%',
            right: '10%'
          })
        }
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_background'))
  }

  @Builder
  mainDashboard() {
    Column({ space: 4 }) {
      Button() {
        Row({ space: $r('app.float.row_space') }) {
          Image($r('app.media.bolt')).width($r('app.float.icon_size_small')).height($r('app.float.icon_size_small'))
          Text($r('app.string.create_reminder'))
            .fontSize($r('app.float.page_text_font_size'))
            .fontColor($r('app.color.black'))
            .fontWeight(FontWeight.Bold)
        }
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('app.color.button_create_background'))
      .width('100%')
      .height($r('app.float.medium_height'))
      .onClick(() => {
        VibrationManager.vibrateClick();
        this.showInputForm = true;
      })

      Button() {
        Row({ space: $r('app.float.row_space') }) {
          Text($r('app.string.show_reminders'))
            .fontSize($r('app.float.page_text_font_size'))
            .fontColor($r('app.color.white'))
        }
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('app.color.button_show_background'))
      .width('100%')
      .height($r('app.float.medium_height'))
      .onClick(() => {
        VibrationManager.vibrateClick();
        this.listReminders();
      })

      Button() {
        Text($r('app.string.cancel_reminder'))
          .fontSize($r('app.float.page_text_font_size'))
          .fontColor($r('app.color.white'))
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('app.color.button_cancel_background'))
      .width('100%')
      .height($r('app.float.medium_height'))
      .onClick(() => {
        VibrationManager.vibrateClick();
        this.cancelReminder();
      })
    }
  }

  @Builder
  addForm() {
    Column({ space: 4 }) {
      TextInput({ placeholder: $r('app.string.input_title_placeholder'), text: this.reminderTitle })
        .onChange((val: string) => this.reminderTitle = val)
        .placeholderColor($r('app.color.gray'))
        .fontColor($r('app.color.white'))
        .backgroundColor($r('app.color.input_title_background'))
        .height($r('app.float.small_height'))
        .fontSize($r('app.float.small_text_font_size'))

      TextInput({ placeholder: $r('app.string.input_content_placeholder'), text: this.reminderContent })
        .onChange((val: string) => this.reminderContent = val)
        .placeholderColor($r('app.color.gray'))
        .fontColor($r('app.color.white'))
        .backgroundColor($r('app.color.input_content_background'))
        .height($r('app.float.small_height'))
        .fontSize($r('app.float.small_text_font_size'))

      TextInput({ placeholder: $r('app.string.input_time_placeholder'), text: this.reminderTime })
        .onChange((val: string) => this.reminderTime = val)
        .type(InputType.Number)
        .placeholderColor($r('app.color.gray'))
        .fontColor($r('app.color.white'))
        .backgroundColor($r('app.color.input_time_background'))
        .height($r('app.float.small_height'))
        .fontSize($r('app.float.small_text_font_size'))

      Button($r('app.string.save_button'))
        .backgroundColor($r('app.color.button_save_background'))
        .width('100%')
        .height($r('app.float.medium_height'))
        .margin({ top: 4 })
        .onClick(() => {
          this.createReminder();
        })

      Text($r('app.string.back_button'))
        .fontSize($r('app.float.back_font_size'))
        .fontColor($r('app.color.gray'))
        .onClick(() => {
          VibrationManager.vibrateClick();
          this.showInputForm = false;
        })
    }
    .padding(4)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius($r('app.float.border_radius_medium'))
  }

  private openNotificationPermission(context: common.UIAbilityContext) {
    notificationManager.requestEnableNotification(context).then(() => {
      Logger.info('Enable notification success');
    }).catch((err: Error) => {
      Logger.error('Enable notification failed: ' + JSON.stringify(err));
    });
  }

  private async createReminder() {
    const timeInSeconds = parseInt(this.reminderTime);

    if (isNaN(timeInSeconds) || timeInSeconds <= 0) {
      VibrationManager.vibrateError();
      this.reminderStatus = $r('app.string.status_invalid_time');
      return;
    }

    if (!this.reminderTitle || !this.reminderContent) {
      VibrationManager.vibrateError();
      this.reminderStatus = $r('app.string.status_missing_fields');
      return;
    }

    let timerReminder: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: timeInSeconds,
      title: this.reminderTitle,
      content: this.reminderContent,
      notificationId: ++this.notificationId
    };

    try {
      const id = await reminderAgentManager.publishReminder(timerReminder);
      this.reminderId = id;
      this.reminderStatus = $r('app.string.status_set');
      this.showInputForm = false;
      this.clearForm();

      VibrationManager.vibrateSuccess();

      await DatabaseManager.saveSetting('lastReminderId', id.toString());
      await DatabaseManager.saveSetting('lastNotificationId', this.notificationId.toString());

    } catch (err) {
      const error = err as BusinessError;
      VibrationManager.vibrateError();
      this.reminderStatus = $r('app.string.status_publish_error');
      Logger.error(`Publish error: ${error.code}`);
    }
  }

  private clearForm() {
    this.reminderTitle = '';
    this.reminderContent = '';
    this.reminderTime = '';
  }

  private listReminders() {
    reminderAgentManager.getValidReminders().then((reminders) => {
      if (reminders.length === 0) {
        this.reminderStatus = $r('app.string.status_no_reminders');
      } else {
        this.reminderStatus = `${this.context.resourceManager.getStringSync($r('app.string.status_total_reminders'))} ${reminders.length}`;
      }
    }).catch((err: BusinessError) => {
      this.reminderStatus = $r('app.string.status_listing_error');
      Logger.error(`Listing error: ${err.code}`);
    });
  }

  private cancelReminder() {
    if (this.reminderId === -1) {
      VibrationManager.vibrateError();
      this.reminderStatus = $r('app.string.status_need_reminder');
      return;
    }

    reminderAgentManager.cancelReminder(this.reminderId).then(async () => {
      VibrationManager.vibrateSuccess();
      this.reminderStatus = $r('app.string.status_canceled');
      this.reminderId = -1;
      await DatabaseManager.saveSetting('lastReminderId', '-1');
    }).catch((err: BusinessError) => {
      VibrationManager.vibrateError();
      this.reminderStatus = $r('app.string.status_cancel_error');
      Logger.error(`Cancel error: ${err.code}`);
    });
  }
}
