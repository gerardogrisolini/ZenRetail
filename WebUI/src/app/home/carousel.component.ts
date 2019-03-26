import { Component, OnInit, OnDestroy } from '@angular/core';
import { AppComponent } from 'app/app.component';
import { environment } from 'environments/environment';

@Component({
    selector: 'app-carousel',
    templateUrl: 'carousel.component.html',
	styleUrls: ['carousel.component.scss']
})

export class CarouselComponent implements OnInit, OnDestroy {

    constructor() {
        AppComponent.setPage('Carousel', true);
    }

    ngOnInit() {
    }

    ngOnDestroy() {
    }
}
