import { MatDialogRef } from '@angular/material';
import { Component } from '@angular/core';

@Component({
    selector: 'confirm-dialog',
    template: `
<p><b>{{ title }}</b></p>
<p>{{ message }}</p>
<br/>
<button mat-raised-button color="primary" (click)="dialogRef.close(true)"><mat-icon>check</mat-icon> {{ 'OK' | translate }}</button>
<button mat-raised-button (click)="dialogRef.close()" style="float: right"><mat-icon>close</mat-icon> {{ 'Cancel' | translate }}</button>
`,
})
export class ConfirmDialog {
    public title: string;
    public message: string;

    constructor(public dialogRef: MatDialogRef<ConfirmDialog>) {
    }
}
