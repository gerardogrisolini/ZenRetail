import { Observable } from 'rxjs/Rx';
import { ConfirmDialog } from 'app/shared/confirm.dialog';
import { MatDialogRef, MatDialog, MatDialogConfig } from '@angular/material';
import { Injectable } from '@angular/core';

@Injectable()
export class DialogService {

    constructor(private dialog: MatDialog) { }

    public confirm(title: string, message: string): Observable<boolean> {
    let dialogRef: MatDialogRef<ConfirmDialog>;
    dialogRef = this.dialog.open(ConfirmDialog);
    dialogRef.componentInstance.title = title;
    dialogRef.componentInstance.message = message;

    return dialogRef.afterClosed();
    }
}
