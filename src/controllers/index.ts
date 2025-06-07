import { Request, Response } from 'express';

export class IndexController {
    getFlavors(req: Request, res: Response): void {
        const flavors = [
            { id: 1, name: 'Vanilla', price: 2.5, image: '/images/vanilla.jpg' },
            { id: 2, name: 'Chocolate', price: 3.0, image: '/images/chocolate.jpg' },
            { id: 3, name: 'Strawberry', price: 2.8, image: '/images/strawberry.jpg' },
        ];
        res.json(flavors);
    }

    getOrders(req: Request, res: Response): void {
        const orders = [
            { id: 1, customerName: 'John Doe', flavor: 'Vanilla', quantity: 2, totalPrice: 5.0 },
            { id: 2, customerName: 'Jane Smith', flavor: 'Chocolate', quantity: 1, totalPrice: 3.0 },
        ];
        res.json(orders);
    }
}