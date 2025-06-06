export class IceCreamService {
    private flavors: Array<{ id: number; name: string; price: number }> = [];

    public addFlavor(name: string, price: number): void {
        const id = this.flavors.length + 1;
        this.flavors.push({ id, name, price });
    }

    public getAllFlavors(): Array<{ id: number; name: string; price: number }> {
        return this.flavors;
    }
}