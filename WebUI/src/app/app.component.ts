import { Component, OnInit, ElementRef, Renderer2, ViewEncapsulation } from '@angular/core';
import { Location } from '@angular/common';
import { OverlayContainer } from '@angular/cdk/overlay';
import { TranslateService } from '@ngx-translate/core';
import { BasketService } from './services/basket.service';
import { ProductService } from './services/product.service';
import { Setting } from 'app/shared/models';
import { Helpers } from 'app/shared/helpers';

@Component({
  moduleId: module.id,
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  encapsulation: ViewEncapsulation.None,
  preserveWhitespaces: false,
})
export class AppComponent implements OnInit {
  public static setting: Setting;
  private static translate: TranslateService;
  private static title = '';
  private static backButton = false;
  private static menuActive = true;
  isIframe = false;
  navItems = [];

  static setPage(title: string, backButton = false, menuActive = true) {
		this.translate.get(title).subscribe((res: string) => AppComponent.title = res);
    AppComponent.backButton = backButton;
    AppComponent.menuActive = menuActive;
  }

  static inIframe() {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
  }

  constructor(
    private translate: TranslateService,
    private location: Location,
    private basketService: BasketService,
    private productService: ProductService,
    private _element: ElementRef
  ) {
    AppComponent.translate = this.translate;

    const country = navigator.language.substring(0, 2).toLowerCase();
    // this language will be used as a fallback when a translation isn't found in the current language
    // this.translate.setDefaultLang('en');
    // the lang to use, if the lang isn't available, it will use the current loader to get them
    this.translate.use(country);
  }

  get title(): string {
    return AppComponent.title;
  }

  get backButton(): boolean {
    return AppComponent.backButton;
  }

  get menuActive(): boolean {
    return AppComponent.menuActive;
  }

  get itemsCount(): number { return this.basketService.count; }

  ngOnInit() {
    this.isIframe = AppComponent.inIframe();
    this.loadSetting();
    if (!this.isIframe) {
      this.loadBasket();
      this.loadCategories();
    }
  }

  loadSetting() {
    if (AppComponent.setting != null) {
      return;
    }
		this.basketService.getSetting()
        .subscribe(result => {
          AppComponent.setting = result;
          Helpers.currency = result.companyCurrency;
          Helpers.utc = result.companyUtc;
        });
  }

  loadCategories() {
    this.navItems.push({ name: 'Home', route: '/home' });
    this.productService.getCategories()
      .subscribe(result => {
        result.forEach(p => this.navItems.push({ name: p.categoryName, route: '/products/' + p.seo.permalink }));
      });
  }

	loadBasket() {
    const uniqueID = localStorage.getItem('uniqueID');
    if (uniqueID == null) {
      return;
    }
		this.basketService.get()
			.subscribe(result => {
				this.basketService.basket = result;
			});
	}

  toggleFullscreen() {
    const elem = this._element.nativeElement.querySelector('.app-content');
    if (elem.requestFullscreen) {
      elem.requestFullscreen();
    } else if (elem.webkitRequestFullScreen) {
      elem.webkitRequestFullScreen();
    } else if (elem.mozRequestFullScreen) {
      elem.mozRequestFullScreen();
    } else if (elem.msRequestFullScreen) {
      elem.msRequestFullScreen();
    }

    // const element = document as any;
    // if (element.exitFullscreen) {
    //     element.exitFullscreen();
    // } else if (element.mozCancelFullScreen) {
    //     element.mozCancelFullScreen();
    // } else if (element.webkitExitFullscreen) {
    //     element.webkitExitFullscreen();
    // } else if (element.msExitFullscreen) {
    //     element.msExitFullscreen();
    // }
  }

  backClick() {
    this.location.back();
  }
}
