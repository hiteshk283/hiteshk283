class IceCream {
    id: number;
    name: string;
    flavor: string;
    price: number;

    constructor(id: number, name: string, flavor: string, price: number) {
        this.id = id;
        this.name = name;
        this.flavor = flavor;
        this.price = price;
    }

    static createIceCream(id: number, name: string, flavor: string, price: number): IceCream {
        return new IceCream(id, name, flavor, price);
    }

    static retrieveIceCream(iceCream: IceCream): string {
        return `Ice Cream - ID: ${iceCream.id}, Name: ${iceCream.name}, Flavor: ${iceCream.flavor}, Price: $${iceCream.price}`;
    }
}

export default IceCream;