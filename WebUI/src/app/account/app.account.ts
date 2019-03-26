import { Component, OnInit, Input } from '@angular/core';
import { Validators, FormControl, FormGroup, FormBuilder } from '@angular/forms';
import { MatSnackBar } from '@angular/material';
import { DialogService } from 'app/services/dialog.service';
import { SessionService } from 'app/services/session.service';
import { RegistryService } from 'app/services/registry.service';
import { Registry } from 'app/shared/models';
import { AppComponent } from 'app/app.component';
import { PasswordValidation } from 'app/shared/password.validation';
import { TranslateService } from '@ngx-translate/core';

@Component({
    selector: 'app-account',
    templateUrl: 'app.account.html'
})

export class AccountComponent implements OnInit {
    @Input('isCheckout') isCheckout: Boolean;
    account: Registry;
    dataform: FormGroup;
	close = 'Close';

    constructor(public snackBar: MatSnackBar,
                private translate: TranslateService,
                private dialogsService: DialogService,
                private sessionService: SessionService,
                private registryService: RegistryService,
                private fb: FormBuilder) {
        this.translate.get(this.close).subscribe((res: string) => this.close = res);
    }

    ngOnInit() {
        if (!this.sessionService.checkCredentials()) { return; }

        if (!this.isCheckout) {
            AppComponent.setPage('Account');
            window.parent.postMessage('iframe:1000', '*');
        }

        this.dataform = this.fb.group({
            'name': new FormControl('', Validators.required),
            'email': new FormControl('', [Validators.required, Validators.email]),
            'phone': new FormControl('', Validators.nullValidator),
            'address': new FormControl('', Validators.required),
            'city': new FormControl('', Validators.required),
            'zip': new FormControl('', [Validators.required, Validators.minLength(5), Validators.maxLength(5)]),
            'province': new FormControl('', [Validators.required, Validators.minLength(2), Validators.maxLength(2)]),
            'country': new FormControl('', [Validators.required, Validators.minLength(3), Validators.maxLength(3)]),
            'fiscalCode': new FormControl('', [Validators.required, Validators.minLength(16), Validators.maxLength(16)]),
            'vatNumber': new FormControl('', [Validators.nullValidator, Validators.minLength(11), Validators.maxLength(11)]),
            'password': new FormControl('', [Validators.nullValidator, Validators.minLength(8), Validators.maxLength(20)]),
			'confirmPassword': new FormControl('', Validators.nullValidator)
        }, {
            validator: PasswordValidation.MatchPassword
        });

        const cutomerId = Number(localStorage.getItem('uniqueID'));
        this.registryService
            .getById(cutomerId)
            .subscribe(result => {
                this.account = result;
            }, onerror => {
                if (onerror.status === 401) {
                    this.sessionService.logout();
                }
                this.snackBar.open(onerror._body, this.close);
            });
    }

    saveClick() {
        this.account.registryPassword = '';
        this.updateClick();
    }

    updateClick() {
        this.registryService
            .update(this.account.registryId, this.account)
            .subscribe(result => {
                this.account.updatedAt = result.updatedAt;
                this.translate.get('Update succesfully!')
                    .subscribe((res: string) => {
                        this.snackBar.open(res, this.close, { duration: 2000 });
                    });
            }, onerror => this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, this.close));
        }

    deleteClick() {
        this.translate.get('Confirm delete')
            .subscribe((title: string) => {
                this.translate.get('Are you sure you want to delete your account?')
                    .subscribe((message: string) => {
                        this.dialogsService
                            .confirm(title, message)
                            .subscribe(res => {
                                if (res) {
                                    this.registryService
                                    .delete(this.account.registryId)
                                    .subscribe(result => {
                                        this.sessionService.removeCredentials();
                                    }, onerror =>
                                        this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, this.close));
                                }
                        });
                    });
            });
    }

    logoutClick() {
        this.sessionService.logout();
    }
}
