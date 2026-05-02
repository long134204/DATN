import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FEEDBACK from '@salesforce/schema/Feedback__c';

export default class CreateForm extends LightningElement {
    objectApiName = FEEDBACK;

    handleSuccess(event) {
        this.toastMessage('Success', 'Record created successfully', 'success');

        
        window.location.reload();

    }
    handleError(error) {
        let message = 'Something went wrong';
        if (error?.detail?.message) {
            message = error.detail.message;
        }

        this.toastMessage('Error', message, 'error');

    }

    toastMessage(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}