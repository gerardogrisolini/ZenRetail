import { Routes } from '@angular/router';
import { ProductsComponent } from 'app/products/app.products';
import { ProductComponent } from 'app/products/app.product';
import { AppComponent } from 'app/app.component';
import { HomeComponent } from 'app/home/home.component';
import { CarouselComponent } from 'app/home/carousel.component';
import { LoginComponent } from 'app/account/app.login';
import { RegisterComponent } from 'app/account/app.register';
import { AccountComponent } from 'app/account/app.account';
import { BasketComponent } from 'app/basket/app.basket';
import { CheckoutComponent } from 'app/basket/app.checkout';
import { OrdersComponent } from 'app/order/app.orders';
import { DocumentComponent } from 'app/order/app.document';


export const APP_ROUTES: Routes = [
  {path: '', component: AppComponent, children: [
    {path: '', redirectTo: 'home', pathMatch: 'full'},
    {path: 'home', component: HomeComponent},
    {path: 'carousel', component: CarouselComponent},
    {path: 'account', component: AccountComponent},
    {path: 'login', component: LoginComponent},
    {path: 'register', component: RegisterComponent},
    {path: 'products/:name', component: ProductsComponent},
    {path: 'product/:name', component: ProductComponent},
    {path: 'basket', component: BasketComponent},
    {path: 'checkout', component: CheckoutComponent},
    {path: 'orders', component: OrdersComponent},
    {path: 'document/:id', component: DocumentComponent}
  ]}
];

export const ALL_ROUTES: Routes = [
  {path: '',  component: AppComponent, children: APP_ROUTES},
];
