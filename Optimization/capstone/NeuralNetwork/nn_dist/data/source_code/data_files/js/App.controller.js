sap.ui.controller("view.App", {

	onListItemTap: function(viewName) {
		app.ref.AppView.splitApp.toDetail(viewName);
		// ensure map is always in sync
		if (viewName == 'map') {
			app.ref.MapView.getController().doMap();
		}
	},

	doReset: function() {
		localStorage.removeItem("Live2.memberId");
		app.ref.AppView.splitApp.toDetail("login");
	}

});
