import { Component, OnInit } from '@angular/core';
import { Validators, FormControl, FormGroup, FormBuilder } from '@angular/forms';
import { MatSnackBar } from '@angular/material';
import { SessionService } from 'app/services/session.service';
import { BasketService } from 'app/services/basket.service';
import { Login } from 'app/shared/models';
import { AppComponent } from 'app/app.component';
import { TranslateService } from '@ngx-translate/core';

@Component({
	selector: 'app-login',
	templateUrl: 'app.login.html'
})

export class LoginComponent implements OnInit {
	dataform: FormGroup;
	public user = new Login('', '');
	close = 'Close';

	constructor(
		private translate: TranslateService,
		public snackBar: MatSnackBar,
		private sessionService: SessionService,
		private basketService: BasketService,
		private fb: FormBuilder
	) {
		AppComponent.setPage('Authentication');
		this.translate.get(this.close).subscribe((res: string) => this.close = res);
		window.parent.postMessage('iframe:300', '*');
	}

	ngOnInit() {
		this.dataform = this.fb.group({
			'email': new FormControl('', [Validators.required, Validators.email]),
			'password': new FormControl('', Validators.required)
		});
	}

	login() {
		this.sessionService.login(this.user)
			.subscribe(result => {
				if (result.login === 'ok') {
					this.sessionService.grantCredentials(result);
					this.loadBasket();
				} else {
					this.snackBar.open(result.error, this.close);
				}
			}, onerror => this.snackBar.open(JSON.stringify(onerror), this.close))
	}

	loadBasket() {
		this.basketService.get()
			.subscribe(result => {
				this.basketService.basket = result;
			});
	}
}
