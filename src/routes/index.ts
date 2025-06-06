import { Router } from 'express';
import IndexController from '../controllers/index';

const router = Router();
const indexController = new IndexController();

export function setRoutes(app) {
    app.use('/flavors', router.get('/', indexController.getFlavors.bind(indexController)));
    app.use('/orders', router.get('/', indexController.getOrders.bind(indexController)));
}