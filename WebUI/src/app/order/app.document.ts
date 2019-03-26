import { Component, OnInit, OnDestroy, ViewChild, ElementRef, Inject } from '@angular/core';
import { DOCUMENT } from '@angular/platform-browser';
import { ActivatedRoute } from '@angular/router';
import { Location } from '@angular/common';
import { MatSnackBar } from '@angular/material';
import { SessionService } from 'app/services/session.service';
import { RegistryService } from 'app/services/registry.service';
import { DocumentService } from 'app/services/document.service';
import { Movement, MovementArticle, PdfDocument } from './../shared/models';
import { AppComponent } from 'app/app.component';
import { environment } from 'environments/environment';

@Component({
    selector: 'app-document',
    templateUrl: 'app.document.html',
	styleUrls: ['app.document.scss']
})

export class DocumentComponent implements OnInit, OnDestroy {
    @ViewChild('doc') doc: ElementRef;
    private sub: any;
    movementId: number;
    totalItems = 0;
    amount = 0.0;
    total = 0.0;
    movement: Movement;
    groups: any[];
    isBusy: Boolean;

    constructor(@Inject(DOCUMENT) private document: any,
                private location: Location,
                public snackBar: MatSnackBar,
                private activatedRoute: ActivatedRoute,
                private sessionService: SessionService,
                private documentService: DocumentService,
                private registryService: RegistryService) {
            AppComponent.setPage('Document', true);
        }

    ngOnInit() {
        this.sessionService.checkCredentials();

        // Subscribe to route params
        this.sub = this.activatedRoute.params.subscribe(params => {
            this.movementId = Number(params['id']);

            this.registryService.getOrderById(this.movementId)
                .subscribe(
                    result => this.movement = result,
                    onerror => this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, 'Close')
                );

            this.registryService.getItemsById(this.movementId)
                .subscribe(
                    result => {
                        this.groups = [];
                        let array: MovementArticle[] = [];
                        let index = 0;
                        result.forEach((item) => {
                            array.push(item);
                            if (index > 21) {
                                this.groups.push(array);
                                array = [];
                                index = -1;
                            }
                            index++;
                        });
                        const lenght = 23 - array.length;
                        for (let i = 0; i < lenght; i++) {
                            array.push(new MovementArticle());
                        }
                        this.groups.push(array);

                        if (result.length > 0) {
                            this.totalItems = result.map(p => p.movementArticleQuantity).reduce((sum, current) => sum + current);
                            this.total = result.map(p => p.movementArticleAmount).reduce((sum, current) => sum + current);
                            this.amount = this.total * 100 / 122;
                        }
                    },
                    onerror => this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, 'Close')
                );
        });
    }

    get header(): string {
        // return environment.apiUrl + '/Media/header.png';
        return '/Media/header.png';
    }

    ngOnDestroy() {
        // Clean sub to avoid memory leak
        this.sub.unsubscribe();
    }

    cancelClick() {
        this.location.back();
    }

    pdfClick() {
        this.isBusy = true;

        const model = new PdfDocument()
        model.subject = this.movement.movementNumber + '.pdf';
        model.content = this.doc.nativeElement.innerHTML;

        this.documentService
            .htmlToPdf(model)
            .subscribe(
                data => {
                    const blob = new Blob([data], {type: 'application/pdf'});
                    const url = window.URL.createObjectURL(blob);
                    window.location.href = url;
                },
                err => {
                    const reader = new FileReader();
                    reader.addEventListener('loadend', (e) =>
                        this.snackBar.open(err.status === 401 ? '401 - Unauthorized' : reader.result, 'Close'));
                    reader.readAsText(err._body);
                },
                () => this.isBusy = false
            );
    }

    sendMailClick() {
        this.isBusy = true;

        const model = new PdfDocument()
        model.address = this.movement.movementRegistry.registryEmail;
        model.subject = 'Document_' + this.movement.movementNumber + '.pdf';
        model.content = this.doc.nativeElement.innerHTML;
        model.zoom = '0.53';

        this.documentService.sendMail(model)
            .subscribe(
                result => this.snackBar.open(result.content),
                onerror => this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, 'Close'),
                () => this.isBusy = false
            );
    }
}
