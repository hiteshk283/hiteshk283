export interface IceCream {
    id: number;
    name: string;
    flavor: string;
    price: number;
}

export interface Order {
    id: number;
    iceCreamId: number;
    quantity: number;
    customerName: string;
    totalPrice: number;
}