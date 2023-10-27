program PasCraft;

{$mode objfpc}{$H+}
uses
  SysUtils,
{$ifdef LINUX}
  Math,
{$endif}
  ctypes,
  CSFMLConfig,
  CSFMLAudio,
  CSFMLGraphics,
  CSFMLNetwork,
  CSFMLSystem,
  CSFMLWindow,
  EngineUnit,
  Vector2Unit,
  RectUnit,
  SpriteUnit;


const 
  WIDTH = 800;
  HEIGHT = 800;
  TILE_WIDTH =  64;
  TILE_HEIGHT = 64;



type Polygon = record
    p1 , p2 , p3 , p4 :Vector2;
end;



function XYToIso(x , y : integer) : Vector2;
begin
    // using matrix multiplication https://pikuma.com/blog/isometric-projection-in-games
    // x * (0.5 * Tw) + y * (-0.5 * Tw)
    //    (0.25 * Th) +     (0.25 * Th)
    
    result.x :=  (x - y) * (TILE_WIDTH  >> 1);
    result.y :=  (x + y) * (TILE_HEIGHT >> 2);
end;

function XYToIso(x , y : cfloat) : sfVector2f;
begin
    result.x :=  (x - y) * (TILE_WIDTH  / 2);
    result.y :=  (x + y) * (TILE_HEIGHT / 4);
end;

function IsoToXY(x , y : integer) : Vector2;
var 
    inv : cfloat;
begin
    // matrix
    // (0.5  * Tw  , -0.5* Tw)
    // (0.25 * Th , 0.25 * Th)

    // inverse of matrix
    // 1/(a*b-c*d) *  (0.25 * Th  , 0.5* Tw)
                    // (-0.25 * Th ,0.5  * Tw)
    
    inv := 1./(TILE_WIDTH  * (TILE_HEIGHT >> 2));
    
    result.x :=  Floor((x  * (TILE_HEIGHT >> 2) + y * (TILE_WIDTH  >> 1)) * inv);
    result.y :=  Floor((-x * (TILE_HEIGHT >> 2) + y * (TILE_WIDTH  >> 1)) * inv);
end;

function XYToIso_pixel(x , y : integer) : Vector2;
begin
    result := XYToIso(x,y);
    // result.x :=  Floor((x - y) / 2);
    // result.y :=  Floor((x + y) / 4);  
end;
function XYToIso_pixel(x , y : cfloat) : sfVector2f;
begin
    result := XYToIso(x,y);

    // result.x :=  (x - y) / 2;
    // result.y :=  (x + y) / 4;  
end;



function IsoToXY_pixel(x , y : integer) : Vector2;
begin
    // matrix
    // (0.5    , -0.5)
    // (0.25 , 0.25)
    // inverse of matrix
    // 4 * (0.25 , 0.5)
    // 4 * (-0.25 , 0.5)
    // result.x :=  4 * Floor(x  *  0.25 - y * 0.5);
    // result.y :=  4 * Floor(x  * 0.25 +  y * 0.5);


    // matrix
    // (0.5  tw   , -0.5 th)
    // (0.25 tw , 0.25   th)
    // inverse of matrix
    // 1/det => 1/(tw * 0.25 th)
    // invser matrix
    // (0.25 th , 0.5 th)
    // (-0.25 tw ,0.5  tw )


    result.x :=  Floor((x + 2 * y) * TILE_HEIGHT / 4) ;
    result.y :=  Floor((-x *  + 2 * y) * TILE_WIDTH / 4);

end;
function IsoToXY_pixel(x , y : cfloat) : sfVector2f;
begin
    result.x :=  (x + 2 * y) * TILE_HEIGHT / 4 ;
    result.y :=  (-x *  + 2 * y) * TILE_WIDTH / 4;


    // result.x := 4 * (x  * 0.25 - y * 0.5);
    // result.y := 4 * (x * 0.25 + y * 0.5);
end;


function AABB(rect1, rect2 : Rect_obj) : boolean;
begin
    result := (rect1.x + rect1.width > rect2.x) and (rect1.y + rect1.height > rect2.y) and
             (rect2.x + rect2.width > rect1.x) and (rect2.y + rect2.height > rect1.y);
end;


procedure max_min_projection_poly_on_vec(poly : array of Vector2; vec : Vector2; var min , max : integer);
begin
    max := -1;
    min := Floor(intPower(2.0,32 - 1));
end;

function collistion_Sat(poly1 , poly2 : Polygon) : boolean;
var 
    i: integer;
    points1 , points2 : array [0..3] of Vector2;
    p1 , p2 : array [0..1] of Vector2;
    
    norm , vec : Vector2;
    
    pmin1 , pmin2 , pmax1, pmax2 : integer;
begin
    points1[0] := poly1.p1; points1[1] := poly1.p2; points1[1] := poly1.p3; points1[1] := poly1.p4;
    points2[0] := poly2.p1; points2[1] := poly2.p2; points2[1] := poly2.p3; points2[1] := poly2.p4;
    
    for i := 0 to 3 do 
    begin
        p1[0] := points1[i];
        p2[1] := points1[(i + 1) mod 4];

        vec.new(p1[0].x - p2[0].x,p1[0].y - p2[0].y);
        norm.new(vec.y,-vec.x);

        max_min_projection_poly_on_vec(points1,norm,pmin1,pmax1);        
        max_min_projection_poly_on_vec(points2,norm,pmin2,pmax2);


        .       .  +  +
        if (pmin1 < pmax2) or (pmin2 < pmax1)

    end;
end;

type Cursor_obj = object
    x , y : integer;
    changed : boolean;
    constructor init(x_ , y_ : integer);
end;


constructor Cursor_obj.init(x_ , y_ : integer);
begin
    x := x_;
    y := y_;
end;



var 
    engine : Engine_obj;
    rect : Rect_obj;

    tile : Sprite_obj;
    selected_tile : Sprite_obj;


    tiles : array [0..20] of integer;
    start_x : integer; 
    start_y : integer; 
    tiles_count_x : integer;
    tiles_count_y : integer;

    cursor : Cursor_obj;

    mouse_rect : Rect_obj;



    mouse_rect_outline : Rect_obj;

    mouse_position : Vector2;



procedure event(event_sf : sfEvent);
var 
    mouseXY : Vector2;
    gridXY : Vector2;
    
    
    gridXY_f : sfVector2f;
    a : sfVector2f;

begin

    if event_sf.type_ = sfEvtKeyPressed then
    begin
        if event_sf.key.code = sfKeyCode.sfKeyRight then
        begin
            cursor.x := (cursor.x + 1) mod tiles_count_x;
            cursor.changed := True;


            gridXY_f := IsoToXY_pixel(1.0,0.0);
            mouse_rect.move(gridXY_f.x,gridXY_f.y);

            // writeln(gridXY_f.x:0:5,' ',gridXY_f.y:0:5);
        end
        else if event_sf.key.code = sfKeyCode.sfKeyLeft then
        begin
            cursor.x -= 1;
            if cursor.x < 0 then
                cursor.x := tiles_count_x - 1; 
            cursor.changed := True;
        

            gridXY_f := IsoToXY_pixel(-16.0,0.0);
            mouse_rect.move(gridXY_f.x,gridXY_f.y);
        end
        else if event_sf.key.code = sfKeyCode.sfKeyDown then
        begin
            cursor.y := (cursor.y + 1) mod tiles_count_y;
            cursor.changed := True;


            gridXY_f := XYToIso_pixel(0.0,10.0);
            mouse_rect.move(gridXY_f.x,gridXY_f.y);
        end
        else if event_sf.key.code = sfKeyCode.sfKeyUp then
        begin
            cursor.y -= 1;
            if cursor.y < 0 then
                cursor.y := tiles_count_y - 1; 
            cursor.changed := True;
        


            gridXY_f := XYToIso_pixel(0.0,-10.0);
            mouse_rect.move(gridXY_f.x,gridXY_f.y);
        end; 
        
    end
    else if (event_sf.type_ = sfEvtMouseMoved) or (event_sf.type_ = sfEvtMouseButtonReleased) then
    begin
        mouse_position.x := event_sf.mouseMove.x;
        mouse_position.y := event_sf.mouseMove.y;
    end
    else if event_sf.type_ = sfEvtMouseButtonPressed then
    begin
        // a := IsoToXY_pixel(cfloat(event_sf.mousebutton.x),cfloat(event_sf.mousebutton.y));


        gridXY_f := XYToIso_pixel(cfloat(event_sf.mousebutton.x),cfloat(event_sf.mousebutton.y));
        mouse_rect.setPosition(gridXY_f.x,gridXY_f.y);
    
        writeln(gridXY_f.x:0:5,' ',gridXY_f.y:0:5);
    end
end;

procedure update();
var 
    tile_rect : Rect_obj;
begin
    // mouse_rect_outline position update
    mouse_rect_outline.setPosition(
                                Floor(Floor(mouse_position.x / mouse_rect_outline.width ) * mouse_rect_outline.width),
                                Floor(Floor(mouse_position.y / mouse_rect_outline.height) * mouse_rect_outline.height)
                                );
    
    tile_rect.x := mouse_rect_outline.x + TILE_WIDTH / 2;
    tile_rect.x := mouse_rect_outline.x + TILE_WIDTH / 2;
end;

procedure render_isomatric_grid();
var 
    line : PsfVertexArray;
    projected : Vector2;


    vertex : sfVertex;

    x , y : integer;

    grid_offset : sfVector2f;


    tile_count_x : integer; 
    tile_count_y : integer; 


begin
    vertex.color    := sfColor_New(0,0,0);
    grid_offset := XYToIso(0.5,-0.5);


    tile_count_x := 2; // 5;
    tile_count_y := 2; // 5;



    line := sfVertexArray_create();
    sfVertexArray_setPrimitiveType(line,sfPrimitiveType.sfLines);

    // draw horizontal lines
    for y := 0 to tile_count_y do 
    begin
        for x := 0 to tile_count_x do 
        begin
            projected := XYToIso(x,y);

            vertex.position.x := projected.x  + start_x + grid_offset.x;      
            vertex.position.y := projected.y  + start_y + grid_offset.y;      
                  
            sfVertexArray_append(line,vertex);

            if (x <> 0) and (x <> tile_count_x) then 
                sfVertexArray_append(line,vertex);
        end;
    end;

    // draw vertical lines
    for x := 0 to  tile_count_x do
    begin
        for y := 0 to tile_count_y do
        begin
            projected := XYToIso(x,y);

            vertex.position.x := projected.x + start_x + grid_offset.x;            
            vertex.position.y := projected.y + start_y + grid_offset.y;            

            sfVertexArray_append(line,vertex);
            if (y <> 0) and (y <> tile_count_y) then
                sfVertexArray_append(line,vertex);
        end;
    end;   

    sfRenderWindow_drawVertexArray(engine.window.window_sf,line,nil);
    sfVertexArray_clear(line); 
    sfVertexArray_destroy(line);

end;


procedure render_grid();
var 
    line : PsfVertexArray;
    x , y : integer;
    tile_count_x : integer; 
    tile_count_y : integer; 


    vertex : sfVertex;
begin
    vertex.color    := sfColor_New(255,255,0);

    tile_count_x := Floor((engine.window.width / TILE_WIDTH) + 0.5); // 5;
    tile_count_y := Floor((engine.window.height / TILE_HEIGHT) + 0.5); // 5;



    line := sfVertexArray_create();
    sfVertexArray_setPrimitiveType(line,sfPrimitiveType.sfLines);

    // draw horizontal lines
    for y := 0 to Floor(tile_count_y) do 
    begin
        for x := 0 to Floor(tile_count_x) do 
        begin
            vertex.position.x := x * TILE_WIDTH   + start_x - TILE_WIDTH / 2;
            vertex.position.y := y * TILE_HEIGHT / 2 + start_y;
                  
            sfVertexArray_append(line,vertex);

            if (x <> 0) and (x <> tile_count_x) then 
                sfVertexArray_append(line,vertex);
        end;
    end;

    // draw vertical lines
    for x := 0 to  Floor(tile_count_x) do
    begin
        for y := 0 to Floor(tile_count_y) do
        begin
            vertex.position.x := x * TILE_WIDTH   + start_x - TILE_WIDTH / 2;
            vertex.position.y := y * TILE_HEIGHT / 2 + start_y;

            sfVertexArray_append(line,vertex);
            if (y <> 0) and (y <> Floor(tile_count_y)) then
                sfVertexArray_append(line,vertex);
        end;
    end;   

    sfRenderWindow_drawVertexArray(engine.window.window_sf,line,nil);


    sfVertexArray_clear(line); 
    sfVertexArray_destroy(line);
end;

procedure render_collistion_boxes();
var 
    line : PsfVertexArray;
    x , y : integer;
    tile_count_x : integer; 
    tile_count_y : integer; 


    vertex : sfVertex;

    projected : Vector2;
begin
    vertex.color    := sfColor_New(255,255,0);

    tile_count_x := Floor((engine.window.width / TILE_WIDTH) + 0.5); // 5;
    tile_count_y := Floor((engine.window.height / TILE_HEIGHT) + 0.5); // 5;



    line := sfVertexArray_create();
    sfVertexArray_setPrimitiveType(line,sfPrimitiveType.sfLines);

    // draw horizontal lines
    for y := 0 to Floor(tile_count_y) do 
    begin
        for x := 0 to Floor(tile_count_x) do 
        begin
            projected := XYToIso(x,y);
            vertex.position.x := projected.x  + start_x;      
            vertex.position.y := projected.y  + start_y;    

            // vertex.position.x := x * TILE_WIDTH   + start_x - TILE_WIDTH / 2;
            // vertex.position.y := y * TILE_HEIGHT / 2 + start_y;
                  
            sfVertexArray_append(line,vertex);

            if (x <> 0) and (x <> tile_count_x) then 
                sfVertexArray_append(line,vertex);
        end;
    end;

    // draw vertical lines
    for x := 0 to  Floor(tile_count_x) do
    begin
        for y := 0 to Floor(tile_count_y) do
        begin
            projected := XYToIso(x,y);
            vertex.position.x := projected.x  + start_x;      
            vertex.position.y := projected.y  + start_y;    



            sfVertexArray_append(line,vertex);
            if (y <> 0) and (y <> Floor(tile_count_y)) then
                sfVertexArray_append(line,vertex);
        end;
    end;   

    sfRenderWindow_drawVertexArray(engine.window.window_sf,line,nil);


    sfVertexArray_clear(line); 
    sfVertexArray_destroy(line);
end;



procedure render();
var
    vec : Vector2;
    temp_vec : sfVector2f;
    x , y : integer;
begin
    engine.window.clear(sfColor_New(135,206,235));

    // writeln('********************************');
    for y := 0 to tiles_count_y - 1 do
    begin
        for x := 0 to tiles_count_x - 1 do
        begin
            if (cursor.x = x) and (cursor.y = y) then
            begin 
                vec := XYToIso(cursor.x,cursor.y);
                if cursor.changed then
                begin
                    cursor.changed := False;
                end;

                vec.x := vec.x * Floor(TILE_WIDTH  / 2) + start_x;
                vec.y := vec.y * Floor(TILE_HEIGHT / 4) + start_y;


                selected_tile.setPosition(vec.x,vec.y);
                selected_tile.render(engine.window);
            end
            else 
            begin
                
                vec := XYToIso(x,y);

                vec.x := vec.x + start_x;
                vec.y := vec.y  + start_y;


                tile.setPosition(vec.x,vec.y);
                tile.render(engine.window);
            end;
        end;
    end;



    render_isomatric_grid();
    // render_grid();
    // render_collistion_boxes();

    mouse_rect.render(engine.window);

    mouse_rect_outline.render_outline(engine.window);
    
end;


var 
    i : integer;
        
begin
    
    engine.window.init('pas-mine',800,600);
    engine.update := @update;  
    engine.render := @render;  
    engine.event := @event;  
    
    
    rect.init(0,0,50,50);
    mouse_rect_outline.init(0,0,TILE_WIDTH,Floor(TILE_WIDTH / 2));

    
    
    tile.fromFile('./art/tile.png');
    tile.scale(2,2);


    selected_tile.fromFile('./art/tile_selected.png');
    selected_tile.scale(1,1);





    start_x := TILE_WIDTH * 4;
    start_y := TILE_WIDTH * 2;
    for i := 0 to 10 do
        tiles[i] := 0;

    tiles_count_x := 2;
    tiles_count_y := 2;

    cursor.init(0,0);
    mouse_rect.init(0,0,10,10);



    mouse_rect.setPosition(32,0);
    
    
    engine.run;
    engine.window.done;
end.


