JustGage.prototype.refreshTitle = function(title) { var obj = this; if (title && (typeof title == "string")) { obj.txtTitle.attr({ "text": title }); }}

$( document ).ready(function() {


  g = new JustGage({
    id: "T202",
    value: 67,
    min: 0,
    max: 100,
    title: "Visitors",
    decimals: 1
  });

  // this.g.refreshTitle("Bla");
  // this.g.txtTitle.attr({ "text": "Arrgh" });


  // this.g.refresh(-10);
  // this.g.refresh(-20);
  // this.g.refreshTitle("Hallo");
  // this.g.refresh(-30);



});
