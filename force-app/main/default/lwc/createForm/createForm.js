import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FEEDBACK from '@salesforce/schema/Feedback__c';

export default class CreateForm extends LightningElement {
    objectApiName = FEEDBACK;

    handleSuccess(event) {
        console.log(event);
        
    }
    handleError(error) {
        console.log(error);
        
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