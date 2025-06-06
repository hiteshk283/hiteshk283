export class IndexController {
    private flavors: string[] = [];
    private orders: any[] = [];

    public getFlavors(req: any, res: any): void {
        res.json(this.flavors);
    }

    public getOrders(req: any, res: any): void {
        res.json(this.orders);
    }

    public addFlavor(req: any, res: any): void {
        const { flavor } = req.body;
        this.flavors.push(flavor);
        res.status(201).json({ message: 'Flavor added successfully', flavor });
    }

    public addOrder(req: any, res: any): void {
        const order = req.body;
        this.orders.push(order);
        res.status(201).json({ message: 'Order placed successfully', order });
    }
}