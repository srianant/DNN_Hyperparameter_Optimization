sap.ui.jsview("view.Map", {

	getControllerName: function() {
		return "view.Map";
	},

	createContent: function(oController) {

		jQuery.sap.declare("app.ref.Map"); 
		app.ref.MapView = this;

		return new sap.m.Page("mapView", {
			title: "{i18n>map}",
			enableScrolling: false,
			showNavButton: true,
			navButtonTap: [oController.onNavButtonTap],
			content: [
				new sap.m.HBox( {id: this.createId("mapCanvas"), alignItems: sap.m.FlexAlignItems.Center})
			]
		});

	}

});
