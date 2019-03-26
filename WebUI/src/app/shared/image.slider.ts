import {
    Component, ElementRef, Renderer, Input, Output,
    Optional, EventEmitter, ViewEncapsulation,
    Pipe, PipeTransform, HostListener
} from '@angular/core';
import { DomSanitizer } from '@angular/platform-browser'

@Pipe({ name: 'safeHtml' })
export class SafeHtmlPipe implements PipeTransform {
    constructor(private sanitized: DomSanitizer) { }
    transform(value) {
        return this.sanitized.bypassSecurityTrustHtml(value);
    }
}

@Component({
    selector: 'image-slider',
    template: `
<div class="slider">
<div class="sliderArrows">
    <a (click)="backWard()"><</a>
    <a (click)="forWard()">></a>
</div>
<ul class="slideShow">
    <li *ngFor="let meta of slides" [ngStyle]="{'display':meta?.hidden?'none':''}" [ngClass]="meta?.classes">
        <div *ngIf="meta.sType=='div'" [innerHtml]="meta.content | safeHtml">
        </div>
        <div *ngIf="meta.sType=='ajaxDiv'">
            Loading...
        </div>
        <img [src]="meta.imgSrc" *ngIf="meta.sType=='img'" class="slide"/>
    </li>
</ul>
</div>`,
    styleUrls: ['image.slider.scss'],
    encapsulation: ViewEncapsulation.None
})
export class ImageSlider {
    /**
     * Play Interval
     */
    @Input() playInterval: any = 2000;
    slides: any;

    @Input('slides') set _slides(s) {
        this.slides = s;
        this.number = this.slides.length;
        if (this.slides.length) { this.slides[0]['classes'] = ['active']; }
    }

    @Input('autoPlay') set _autoPlay(b: boolean) {
        this.autoPlay = b
        if (b) {
            this.auto(this.playInterval);
        }
    }
    currentElement = 0;
    autoPlay = false;
    number = 0;
    intervalTime = 1000;
    private delayHideSetTimeOutControl: any;
    constructor() {
    }
    backWard() {
        if (this.autoPlay) { clearInterval(this.playInterval); }
        this.currentElement = this.currentElement - 1;
        if (this.currentElement < 0) {
            this.currentElement = this.number - 1;
        }
        this.removeClasses();
        const prev = this.currentElement === this.number - 1 ? 0 : this.currentElement + 1;
        this.slides[prev].classes = ['animateForward'];
        this.show(this.slides[prev]);
        this.show(this.slides[this.currentElement]);

        clearTimeout(this.delayHideSetTimeOutControl);

        this.delayHideSetTimeOutControl = this.delayHide(this.slides[prev], 1100);
        this.slides[this.currentElement].classes = ['active', 'backward'];
        if (this.autoPlay) { this.auto(this.intervalTime); }
    }

    removeClasses() {
        for (let i = 0; i < this.number; i++) {
            this.slides[i].classes = {}
        }
    }
    forWard() {
        if (this.autoPlay) { clearInterval(this.playInterval); }
        this._forWard();
        if (this.autoPlay) { this.auto(this.intervalTime); }
    }
    private _forWard() {
        this.currentElement = 1 + this.currentElement;
        if (this.currentElement >= this.number) {
            this.currentElement = 0;
        }
        this.removeClasses();
        const prev = this.currentElement === 0 ? this.number - 1 : this.currentElement - 1;
        this.slides[prev]['classes'] = ['animateBack'];

        // this.show(this.slides[prev]);
        this.show(this.slides[this.currentElement]);

        clearTimeout(this.delayHideSetTimeOutControl);
        this.delayHideSetTimeOutControl = this.delayHide(this.slides[prev], 1100);
        this.slides[this.currentElement].classes = ['active', 'forward'];
    }
    auto(ms) {
        this.autoPlay = true;
        this.intervalTime = ms;
        this.playInterval = setInterval(this._forWard.bind(this), ms);
    }
    delayHide(el, ms) {
        return setTimeout(() => el.hidden = true, ms);
    }
    show(el) {
        el.hidden = false;
    }
}
