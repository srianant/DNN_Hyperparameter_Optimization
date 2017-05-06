sap.ui.jsview("view.Overview", {

	getControllerName: function() {
		return "view.Overview";
	},

	createContent: function(oController) {

		return new sap.m.Page( { 
			title: "{i18n>overview}",
			showNavButton: true,
			navButtonTap: [oController.onNavButtonTap],
			content: [
			new sap.ui.core.HTML({
				content: '<iframe id="ytPlayer" width="100%" height="100%" src="http://www.youtube.com/embed/Uq2lSpXXK00?feature=player_detailpage" frameborder="0" allowfullscreen></iframe>'
				}) 
			]
		});

	}

});
