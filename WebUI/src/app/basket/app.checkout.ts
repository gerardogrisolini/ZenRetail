import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { MatSnackBar, MatSelectionList } from '@angular/material';
import { DialogService } from 'app/services/dialog.service';
import { SessionService } from 'app/services/session.service';
import { BasketService } from 'app/services/basket.service';
import { Basket, Order, Item, Registry, Setting } from 'app/shared/models';
import { AppComponent } from 'app/app.component';
import { Observable } from 'rxjs/Rx';
import { AccountComponent } from 'app/account/app.account';

declare let paypal: any;

@Component({
	selector: 'app-checkout',
	templateUrl: 'app.checkout.html',
	styleUrls: ['app.checkout.scss']
})

export class CheckoutComponent implements OnInit {
    @ViewChild('account') component: AccountComponent;
	payments: Item[] = [];
	shippings: Item[] = [];
	shippingCost = 0.0;
	shippingMethod = '';
	paymentMethod = '';

	constructor(
		public snackBar: MatSnackBar,
		private router: Router,
		private dialogsService: DialogService,
		private sessionService: SessionService,
		private basketService: BasketService) {
		AppComponent.setPage('Checkout', true);
	}

	ngOnInit() {
		if (!this.sessionService.checkCredentials()) { return; }

		window.parent.postMessage('iframe:900', '*');

		this.basketService
			.getPayments()
			.subscribe(result => this.payments = result);

		this.basketService
			.getShippings()
			.subscribe(result => this.shippings = result);
	}

	get customer(): string { return this.component.account ? this.component.account.registryName : ''; }

	get isValidAccount(): Boolean { return this.component.dataform.valid; }
	get isValidShipping(): Boolean { return this.shippingMethod !== ''; }
	get isValidPayment(): Boolean { return this.paymentMethod !== ''; }

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
    get shipping(): string {
		const item = this.shippings.find(p => p.id === this.shippingMethod);
		return item ? item.value : '';
	}
    get payment(): string {
		const item = this.payments.find(p => p.id === this.paymentMethod);
		return item
		? item.value
		: '';
	}

	paymentClick(event) {
		if (this.isValidAccount && this.paymentMethod === 'PayPal') {
			this.showPayPal(AppComponent.setting, this.amount + this.shippingCost);
		}
	}

	shippingClick(event) {
		this.basketService
			.getShippingCost(this.shippingMethod)
			.subscribe(result => {
				this.shippingCost = result.value;
			});
	}

	showPayPal(info: Setting, total: number) {
		paypal.Button.render({
			style: {
				size: 'responsive',
				label: 'checkout'
			},
			// sandbox | production
			env: info.paypalEnv,
			// PayPal Client IDs - replace with your own
			// Create a PayPal app: https://developer.paypal.com/developer/applications/create
			client: {
				sandbox:    info.paypalSandbox, // 'ARVxxnTeHt9gA6rK6n6WFx-3XuJuof9qJuK-FeZi_Xnq0hc8acg8jWs2P8jWaZS-4N23Pa2SzG80ZCCH'
				production: info.paypalProduction // 'AXHnIw3mLFqSrPVVraoRWewhBWTEGNsbrGjSzYS8r9wmyydLv2AUR2rUswKGZvKwHyyYrGSuuY2I9afp'
			},
			// Show the buyer a 'Pay Now' button in the checkout flow
			commit: true,
			// payment() is called when the button is clicked
			payment: function(data, actions) {
				// Make a call to the REST api to create the payment
				return actions.payment.create({
					payment: {
						transactions: [{
							amount: { total: total, currency: info.companyCurrency }
						}]
					}
				});
			},
			// onAuthorize() is called when the buyer approves the payment
			onAuthorize: function(data, actions) {
				// Make a call to the REST api to execute the payment
				return actions.payment.execute().then(function() {
					actions.payment.get().then(function(p) {
						if (p.state === 'approved') {
							console.log(p);
							window.alert('Payment approved succesfully!');
							this.commitCheckout(p.id);
						} else {
							console.log(p);
						}
					});
				});
			},
			onCancel: function(data, actions) {
				/*
				* Buyer cancelled the payment
				*/
			},
			onError: function(err) {
				/*
				* An error occurred during the transaction
				*/
			}
		}, '#paypal-container');
	}

	confirmClick() {
        this.dialogsService
			.confirm('Confirm order', 'Are you sure you want to confirm this order?')
			.subscribe(res => {
				if (res) {
					this.commitOrder('');
				}
			});
	}

	commitOrder(paypalKey: string) {
		const order = new Order();
		order.payment = this.paymentMethod;
		order.shipping = this.shippingMethod;
		order.shippingCost = this.shippingCost;
		order.paypal = paypalKey;
		this.basketService
			.commit(order)
			.subscribe(p => {
				this.snackBar
				.open('Successfully registered order n.' + p.movementNumber, 'Show Orders', {
					duration: 5000
				})
				.onAction()
				.subscribe(() => {
					this.router.navigate(['orders']);
				});
		});
	}
}
