import { Component, OnInit, OnDestroy, Inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Title, Meta } from '@angular/platform-browser';
import { MatSnackBar } from '@angular/material';
import { TranslateService } from '@ngx-translate/core';
import { ProductService } from 'app/services/product.service';
import { BasketService } from 'app/services/basket.service';
import { Product, Article, Basket } from 'app/shared/models';
import { AppComponent } from 'app/app.component';
import { ParseUrlPipe } from 'app/pipes/parseurl.pipe';

@Component({
	moduleId: module.id,
	selector: 'app-product',
	templateUrl: 'app.product.html',
	styleUrls: ['app.product.scss']
})
export class ProductComponent implements OnInit, OnDestroy {
	private sub: any;
	product: Product;
	images: Array<any>;

	constructor(
		private titleService: Title,
		private metaService: Meta,
		private router: Router,
		private snackBar: MatSnackBar,
		private translate: TranslateService,
		private productService: ProductService,
		private basketService: BasketService,
		private activatedRoute: ActivatedRoute
	) {	}

	get isIframe(): boolean { return AppComponent.inIframe(); }

	ngOnInit() {
		this.images = [];
		if (localStorage.getItem('barcode')) {
			this.pickerClick(null);
		}
		this.sub = this.activatedRoute.params.subscribe(params => {
			const name = params['name'];
			this.loadProduct(name);
		});
	}

  ngOnDestroy() {
		// Clean sub to avoid memory leak
		this.sub.unsubscribe();
  }

  loadProduct(name: string) {
		this.productService.getByProductName(name)
			.subscribe(result => {
				this.product = result;
				AppComponent.setPage(result.productName, !this.isIframe, !this.isIframe);
				if (!this.isIframe) {
					/// SEO
					const country = navigator.language.substring(0, 2).toUpperCase();
					// Changing title
					let title = result.productName;
					if (result.seo.title.length > 0) {
						const translate = result.seo.title.find(p => p.country === country);
						if (translate) {
							title = translate.value;
						}
					}
					this.titleService.setTitle(title);
					// Changing meta with name="description"
					if (result.seo.description.length > 0) {
						const translate = result.seo.description.find(p => p.country === country);
						if (translate) {
							this.metaService.removeTag('name="description"');
							this.metaService.addTag({ name: 'description', content: translate.value }, false);
						}
					}

					this.product.medias.forEach(m => {
						this.images.push({ 'sType': 'img', 'imgSrc': new ParseUrlPipe().transform([m]) });
					});
				} else {
					const height = (result.attributes.length * 100) + 160;
					window.parent.postMessage('iframe:' + height, '*');
				}
		}, onerror => {
				this.translate.get('Close').subscribe((res: string) =>
					this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, res)
				);
			});
  }

	pickerClick(event: Article) {
		const model = new Basket();
		if (event !== null) {
			model.basketBarcode = event.barcodes.find(p => p.tags.length === 0).barcode;
			localStorage.setItem('barcode', model.basketBarcode);
		} else {
			model.basketBarcode = localStorage.getItem('barcode');
		}
		this.basketService
			.create(model)
			.subscribe(result => {
				localStorage.removeItem('barcode');
				this.translate.get('added to basket!')
					.subscribe((message: string) => {
						this.translate.get('Show Basket')
							.subscribe((action: string) => {
								this.snackBar.open(model.basketBarcode + ' ' + message, action, {
									duration: 5000
								})
								.onAction()
								.subscribe(() => {
									if (this.isIframe) {
											window.parent.postMessage('basket', '*');
									} else {
										this.router.navigate(['basket']);
									}
								});
							});
					});
				if (!this.isIframe) {
				const basket = this.basketService.basket.find(p => p.basketBarcode === model.basketBarcode);
				if (basket) {
					basket.basketQuantity += 1.0;
				} else {
					this.basketService.basket.push(result);
					}
				} else {
					window.parent.postMessage('token:' + localStorage.getItem('token'), '*');
				}
			},
			onerror => {
				this.translate.get('You must login before adding to basket')
					.subscribe((message: string) => {
						this.translate.get('Login')
							.subscribe((login: string) => {
								this.snackBar.open(onerror.status === 401 ? message : onerror._body, login)
									.onAction()
									.subscribe(() => {
										localStorage.setItem('origin', this.router.url);
										this.router.navigate(['login']);
									});
							});
					});
			});
	}
}
