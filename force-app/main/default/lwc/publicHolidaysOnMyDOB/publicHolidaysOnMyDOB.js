import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHolidays from '@salesforce/apex/PublicHolidaysOnMyDOBController.getHolidays';

export default class PublicHolidaysOnMyDOB extends LightningElement {
    idNumber = '8001015001080';
    error = '';
    isError;
    isSuccess;
    publicHolidays;
    isLoading=false; 

    btnDisabled=false; 

    columns = [
        { label: 'Holiday', fieldName: 'name' },
        { label: 'Description', fieldName: 'description' },
        { label: 'Date', fieldName: 'date', type: 'date',typeAttributes:{
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "2-digit"
        } },
    ];

    handleIdNumberChange(event) {
        this.btnDisabled = false; 
        this.isError = false;
        this.idNumber = event.target.value;
       console.log('valid id :'+ this.isValidSAID(this.idNumber));
     if(this.btnDisabled){
        this.isError = true;
     }
    }

    isValidSAID(id) {
        var i, c,
            even = '',
            sum = 0,
            check = id.slice(-1);
    
        if (id.length != 13 || id.match(/\D/)) {
            this.btnDisabled = true; 
            this.isError = true;

            return false;

        }
        id = id.substr(0, id.length - 1);
        for (i = 0; c = id.charAt(i); i += 2) {
            sum += +c;
            even += id.charAt(i + 1);
        }
        even = '' + even * 2;
        for (i = 0; c = even.charAt(i); i++) {
            sum += +c;
        }
        sum = 10 - ('' + sum).charAt(1);
        this.btnDisabled = ('' + sum).slice(-1) == check ? false : true; 
        this.isError =  ('' + sum).slice(-1) == check ? false : true;

        return ('' + sum).slice(-1) == check;
    }
 
  
    handleSearch() {
        this.isLoading=true;

        // Validate on click

        if (this.idNumber.length !== 13) {
            return false;
        }

        var ex = /^(((\d{2}((0[13578]|1[02])(0[1-9]|[12]\d|3[01])|(0[13456789]|1[012])(0[1-9]|[12]\d|30)|02(0[1-9]|1\d|2[0-8])))|([02468][048]|[13579][26])0229))(( |-)(\d{4})( |-)(\d{3})|(\d{7}))/;
        
        if (ex.test(this.idNumber)) {
            this.isError=false;
            this.saveSearchData(this.idNumber);
           // this.isLoading=false;
        }else{
            this.isError=true;
            this.isSuccess=false;
            this.publicHolidays=undefined;
            this.isLoading=false;
        }
    }


    saveSearchData(idNumber) {
        console.log(idNumber);
        getHolidays({ saIdNumber: this.idNumber })
            .then((result) => {
                console.log(result);
                this.error = undefined;
                this.publicHolidays=result;
                this.isLoading=false;
                this.isSuccess=true;

                    const event = new ShowToastEvent({
                        title: 'Successfully checked!',
                        message: result.length + ' records has been found!' ,
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                
            })
            .catch((error) => {
                console.log('error >'+ JSON.stringify(error));
                this.error = error;
                this.isLoading=false;
            });
    }

   
}