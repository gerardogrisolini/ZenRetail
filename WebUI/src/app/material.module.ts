import { NgModule } from '@angular/core';

import {
  MatExpansionModule,
  MatListModule,
  MatToolbarModule,
  MatButtonModule,
  MatIconModule,
  MatCardModule,
  MatSidenavModule,
  MatGridListModule,
  MatCheckboxModule,
  MatRadioModule,
  MatInputModule,
  MatDialogModule,
  MatSnackBarModule,
  MatSelectModule,
  MatStepperModule,
  MatTableModule
} from '@angular/material';

@NgModule({
  imports: [
    MatExpansionModule,
    MatListModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatSidenavModule,
    MatGridListModule,
    MatCheckboxModule,
    MatRadioModule,
    MatInputModule,
    MatDialogModule,
    MatSnackBarModule,
    MatSelectModule,
    MatStepperModule,
    MatTableModule
  ],
  exports: [
    MatExpansionModule,
    MatListModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatSidenavModule,
    MatGridListModule,
    MatCheckboxModule,
    MatRadioModule,
    MatInputModule,
    MatDialogModule,
    MatSnackBarModule,
    MatSelectModule,
    MatStepperModule,
    MatTableModule
  ]
})
export class MaterialModule { }
