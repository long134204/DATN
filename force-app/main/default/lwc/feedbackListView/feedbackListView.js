import { LightningElement, wire } from 'lwc';
import getFeedbacks from '@salesforce/apex/feedbackListController.getFeedbacks';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FeedbackListView extends LightningElement {
    columns = [
        { label: 'Subject', fieldName: 'Subject__c',},
        { label: 'Id', fieldName: 'Id',},
        { label: 'Description', fieldName: 'Description__c'},
        { label: 'Type', fieldName: 'Type__c',},
        { label: 'Category', fieldName: 'Category__c', },
        { label: 'Name', fieldName: 'Name', hidden: true },
    ];
    feedbacks =[];
    currentData = [];
    disabledPrev = true;
    disabledNext = true;
    keyword = '';
    currentPage = 1;
    pageNumber = 10;
    totalPage;

    getFeedbackUrl(id, name){
        return '/s/feedback/' + id +'/' +name;
    }

    get totalRecord() {
        return this.feedbacks.length > 0 ? 'Feedbacks ('+this.feedbacks.length +')' : 'Feedbacks (0) ';
    }

    handleSearch() {
        if(this.keyword != '') {
            getFeedbacks({ keyword: this.keyword })
            .then(result => {
                if (result.length >0) {
                    this.feedbacks = result.map((item) =>{
                        return {
                            ...item,
                            url: this.getFeedbackUrl(item.Id, item.Name)
                        }
                    });
                    this.handlePaging();
                } else {
                    this.toastMessage('Error', 'Can\'t find your keyword', 'error');
                }
            })
            .catch(error => {
                this.toastMessage('Error', 'Some thing wrong, please contact your admin', 'error');
            });
        } else {
            this.toastMessage('Error', 'Please enter keyword to search', 'error');
        }
    }

    handleChange(event) {
        this.keyword = event.target.value;
    }

    handlePaging() {
        this.totalPage = Math.ceil(this.feedbacks.length / this.pageNumber);
        let start = (this.currentPage - 1) * this.pageNumber;
        let end = this.currentPage * this.pageNumber;
        this.currentData = this.feedbacks.slice(start, end);
        this.checkShowNextPrev();
    }

    checkShowNextPrev() {
        if(this.currentPage < this.totalPage) {
            this.disabledNext = false;
        } else {
            this.disabledNext = true;
        }
        if(this.currentPage > 1 ) {
            this.disabledPrev = false;
        } else {
            this.disabledPrev = true;
        }
    }

    handlePrevMaster(event) {
        if(this.currentPage > 1) {
            this.currentPage = this.currentPage - 1;
            this.handlePaging();
        }
    }

    handleNextMaster(event) {
        if(this.currentPage < this.totalPage) {
            this.currentPage = this.currentPage + 1;
            this.handlePaging();
        }
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