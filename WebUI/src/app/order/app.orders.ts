import { Component, OnInit } from '@angular/core';
import { DataSource } from '@angular/cdk/collections';
import { MatSnackBar } from '@angular/material';
import { TranslateService } from '@ngx-translate/core';
import { SessionService } from 'app/services/session.service';
import { RegistryService } from 'app/services/registry.service';
import { Movement } from 'app/shared/models';
import { AppComponent } from 'app/app.component';
import { Observable } from 'rxjs/Rx';

@Component({
	selector: 'app-orders',
	templateUrl: 'app.orders.html',
	styleUrls: ['app.orders.scss']
})

export class OrdersComponent implements OnInit {

	dataSource: OrderDataSource;
	displayedColumns = ['number', 'date', 'amount', 'payment', 'status', 'doc'];

	constructor(
		public snackBar: MatSnackBar,
		private translate: TranslateService,
		private sessionService: SessionService,
		private registryService: RegistryService) {
		AppComponent.setPage('Orders');
	}

	ngOnInit() {
		if (!this.sessionService.checkCredentials()) { return; }

		this.loadOrders();
	}

	loadOrders() {
		this.registryService.getOrders()
			.subscribe(result => {
				this.dataSource = new OrderDataSource(result);
				const height = (result.length * 50) + 255;
				window.parent.postMessage('iframe:' + height, '*');
			},
			onerror => {
				this.translate.get('Close').subscribe((close: string) =>
					this.snackBar.open(onerror.status === 401 ? '401 - Unauthorized' : onerror._body, close)
				);
			});
	}
}

export class OrderDataSource extends DataSource<any> {

	orders: Movement[] = [];

	constructor(orders: Movement[]) {
		super();
		this.orders = orders;
	};

	connect(): Observable<Movement[]> {
	  return Observable.of(this.orders);
	}

	disconnect() {}
}
