import { Component, OnInit } from '@angular/core';
import { MatSnackBar, MatSelectionList } from '@angular/material';
import { TranslateService } from '@ngx-translate/core';
import { DialogService } from 'app/services/dialog.service';
import { SessionService } from 'app/services/session.service';
import { BasketService } from 'app/services/basket.service';
import { Basket } from 'app/shared/models';
import { AppComponent } from 'app/app.component';
import { Observable } from 'rxjs/Rx';

@Component({
	selector: 'app-basket',
	templateUrl: 'app.basket.html',
	styleUrls: ['app.basket.scss']
})

export class BasketComponent implements OnInit {
	private sub: any;

	constructor(
		public snackBar: MatSnackBar,
		private translate: TranslateService,
		private dialogsService: DialogService,
		private sessionService: SessionService,
		private basketService: BasketService) {
		AppComponent.setPage('Basket');
	}

	get isIframe(): boolean { return AppComponent.inIframe(); }

	ngOnInit() {
		if (!this.sessionService.checkCredentials()) { return; }

		if (this.isIframe) {
			this.basketService.get()
				.subscribe(result => {
					this.basketService.basket = result;
					const height = (result.length * 160) + 255;
					window.parent.postMessage('iframe:' + height, '*');
				});
		}
	  }

	get basket(): Basket[] { return this.basketService.basket; }
	get count(): number {
		return this.basket.length > 0
		? this.basket.map(p => p.basketQuantity).reduce((sum, current) => sum + current)
		: 0;
	}
	get amount(): number {
		return this.basket.length > 0
		? this.basket.map(p => p.basketQuantity * p.basketPrice).reduce((sum, current) => sum + current)
		: 0;
	}

	updateClick(item: Basket) {
		this.basketService
			.update(item.basketId, item)
			.subscribe(result => {
				const index = this.basket.indexOf(item);
				this.basketService.basket[index] = item;
				window.parent.postMessage('token:' + localStorage.getItem('token'), '*');
			});
	}

	deleteClick(items: MatSelectionList) {
        this.translate.get('Confirm delete')
		.subscribe((title: string) => {
			this.translate.get('Are you sure you want to delete selected items?')
				.subscribe((message: string) => {
					this.dialogsService
						.confirm(title, message)
						.subscribe(res => {
							if (res) {
								items.selectedOptions.selected.forEach(item => {
									this.basketService
									.delete(item.value.basketId)
									.subscribe(result => {
										const index = this.basket.indexOf(item.value);
										this.basket.splice(index, 1);
										window.parent.postMessage('token:' + localStorage.getItem('token'), '*');
									});
								});
							}
						});
				});
		});
	}
}
