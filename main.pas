unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Zipper, LCLType,
  StdCtrls, OpenGLContext, uos_flat, gl;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    OpenGLControl1: TOpenGLControl;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure OpenGLControl1Paint(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  TMPDir : String;

  UOS_Lib_Check : Boolean;

  CubeSize : Integer;

  var texi : Integer;

implementation

{$R *.lfm}

{ TForm1 }

//
//
//   РАБОТА С РЕСУРСАМИ
//
//

// Удаление рекурсивное директории
procedure DeleteDirectory(const Name: string);
var
  F: TSearchRec;
begin
  if FindFirst(Name + '\*', faAnyFile, F) = 0 then begin
    try
      repeat
        if (F.Attr and faDirectory <> 0) then begin
          if (F.Name <> '.') and (F.Name <> '..') then begin
            DeleteDirectory(Name + '\' + F.Name);
          end;
        end else begin
          DeleteFile(Name + '\' + F.Name);
        end;
      until FindNext(F) <> 0;
    finally
      FindClose(F);
    end;
    RemoveDir(Name);
  end;
end;

// Создание временной папки
procedure CreateTMPDir();
var
  Path : String;
begin
  Path := GetTempDir();
  Path := Path + 'Platformer';

  DeleteDirectory(Path);
  if (CreateDir(Path)) then
     TMPDir := Path
  else
  begin
     TMPDir := 'Platformer';
     if not CreateDir(Path) then
     begin
        ShowMessage('Can''t create temp folder');
        Application.Terminate;
     end;
  end;

end;

// Процедура распаковки библиотек
procedure UnpackLibs();
var
  S: TResourceStream;
  UnZipper: TUnZipper;
  LibPath : String;
begin

     // Создание директории бибдлиотек
     LibPath := TMPDir +  DirectorySeparator + 'libs';
     if not CreateDir(LibPath) then
     begin
        ShowMessage('Can''t create lib folder');
        Application.Terminate;
     end;

     // UOS
     S := TResourceStream.Create(HInstance, 'UOS', RT_RCDATA);
     S.SaveToFile(TMPDir +  DirectorySeparator + 'uos.zip');
     S.Free;

    UnZipper := TUnZipper.Create;
    UnZipper.FileName := TMPDir +  DirectorySeparator + 'uos.zip';
    UnZipper.OutputPath := LibPath;
    UnZipper.Examine;
    UnZipper.UnZipAllFiles;
    UnZipper.Free;
    DeleteFile(TMPDir +  DirectorySeparator + 'uos.zip');

end;

// Процедура распаковки ассетов
procedure UnpackAssets();
var
  S: TResourceStream;
  UnZipper: TUnZipper;
  AssetsPath : String;
begin
     // Создание директории ассетов
     AssetsPath := TMPDir +  DirectorySeparator + 'assets';
     if not CreateDir(AssetsPath) then
     begin
        ShowMessage('Can''t create assets folder');
        Application.Terminate;
     end;

    // Распаковка ассетов
    S := TResourceStream.Create(HInstance, 'ASSETS', RT_RCDATA);
    S.SaveToFile(TMPDir +  DirectorySeparator + 'assets.zip');
    S.Free;

    UnZipper := TUnZipper.Create;
    UnZipper.FileName := TMPDir +  DirectorySeparator + 'ASSETS.zip';
    UnZipper.OutputPath := AssetsPath;
    UnZipper.Examine;
    UnZipper.UnZipAllFiles;
    UnZipper.Free;
    DeleteFile(TMPDir +  DirectorySeparator + 'ASSETS.zip');
end;

//
//
//   РАБОТА С БИБЛИОТЕКАМИ
//
//

// Загрузка библиотек
procedure LoadLibs();
var
  LibPath : String;
  PA, SF, MP : String;
  Check : Integer;

begin

    LibPath := TMPDir +  DirectorySeparator + 'libs';

    // Построение путей
    {$IFDEF Windows}
       {$if defined(cpu64)}
            PA := LibPath + DirectorySeparator + 'uos\Windows\64bit\LibPortaudio-64.dll';
            SF := LibPath + DirectorySeparator + 'uos\Windows\64bit\LibSndFile-64.dll';
            MP := LibPath + DirectorySeparator + 'uos\Windows\64bit\LibMpg123-64.dll';
       {$else}
            PA := LibPath + DirectorySeparator + 'uos\Windows\32bit\LibPortaudio-32.dll';
            SF := LibPath + DirectorySeparator + 'uos\Windows\32bit\LibSndFile-32.dll';
            MP := LibPath + DirectorySeparator + 'uos\Windows\32bit\LibMpg123-32.dll';
         {$endif}
     {$ENDIF}

     {$if defined(CPUAMD64) and defined(linux) }
        PA := LibPath + DirectorySeparator + 'uos/Linux/64bit/LibPortaudio-64.so';
        SF := LibPath + DirectorySeparator + 'uos/Linux/64bit/LibSndFile-64.so';
        MP := LibPath + DirectorySeparator + 'uos/Linux/64bit/LibMpg123-64.so';
     {$ENDIF}

     {$if defined(cpu86) and defined(linux)}
        PA := LibPath + DirectorySeparator + 'uos/Linux/32bit/LibPortaudio-32.so';
        SF := LibPath + DirectorySeparator + 'uos/Linux/32bit/LibSndFile-32.so';
        MP := LibPath + DirectorySeparator + 'uos/Linux/32bit/LibMpg123-32.so';
     {$ENDIF}

     {$if defined(linux) and defined(cpuaarch64)}
        PA := LibPath + DirectorySeparator + 'uos/Linux/aarch64_raspberrypi/libportaudio_aarch64.so';
        SF := LibPath + DirectorySeparator + 'uos/Linux/aarch64_raspberrypi/libsndfile_aarch64.so';
        MP := LibPath + DirectorySeparator + 'uos/Linux/aarch64_raspberrypi/libmpg123_aarch64.so';
     {$ENDIF}

     {$if defined(linux) and defined(cpuarm)}
        PA := LibPath + DirectorySeparator + 'uos/Linux/arm_raspberrypi/libportaudio-arm.so';
        SF := LibPath + DirectorySeparator + 'uos/Linux/arm_raspberrypi/libsndfile-arm.so';
        MP := LibPath + DirectorySeparator + 'uos/Linux/arm_raspberrypi/libmpg123-arm.so';
     {$ENDIF}

     {$IFDEF freebsd}
        {$if defined(cpu64)}
          PA := LibPath + DirectorySeparator + 'uos/FreeBSD/64bit/libportaudio-64.so';
          SF := LibPath + DirectorySeparator + 'uos/FreeBSD/64bit/libsndfile-64.so';
          MP := LibPath + DirectorySeparator + 'uos/FreeBSD/64bit/libmpg123-64.so';
        {$else}
          PA := LibPath + DirectorySeparator + 'uos/FreeBSD/32bit/libportaudio-32.so';
          SF := LibPath + DirectorySeparator + 'uos/FreeBSD/32bit/libsndfile-32.so';
          MP := LibPath + DirectorySeparator + 'uos/FreeBSD/32bit/libmpg123-32.so';
        {$endif}
     {$ENDIF}

     {$IFDEF Darwin}
        {$IFDEF CPU32}
          PA := LibPath + DirectorySeparator + 'uos/Mac/32bit/LibPortaudio-32.dylib';
          SF := LibPath + DirectorySeparator + 'uos/Mac/32bit/LibSndFile-32.dylib';
          MP := LibPath + DirectorySeparator + 'uos/Mac/32bit/LibMpg123-32.dylib';
        {$ENDIF}

        {$IFDEF CPU64}
          PA := LibPath + DirectorySeparator + 'uos/Mac/64bit/LibPortaudio-64.dylib';
          SF := LibPath + DirectorySeparator + 'uos/lib/Mac/64bit/LibSndFile-64.dylib';
          MP := LibPath + DirectorySeparator + 'uos/lib/Mac/64bit/LibMpg123-64.dylib';
        {$ENDIF}
     {$ENDIF}

     // Загрузка UOS
     Check := uos_LoadLib(Pchar(PA), Pchar(SF), Pchar(MP), nil, nil, nil);
     if Check = 0 then
        UOS_Lib_Check := true
     else
     begin
       // Если не нашел библиотеки кастомные - пробуем системные
       Check := uos_LoadLib(PChar('system'), PChar('system'), PChar('system'), nil, nil, nil);
       UOS_Lib_Check := (Check = 0);
     end;

end;

//
//
//   РАБОТА С АУДИО
//
//

// Начать проигрывание фоновой музыки
procedure PlayMusicBG();
begin
     if UOS_Lib_Check then
     begin
       uos_CreatePlayer(0);
       uos_AddFromFile(0, PChar(TMPDir +  DirectorySeparator + 'assets' + DirectorySeparator + 'sound' + DirectorySeparator + 'bg_sound.mp3'));
       {$if defined(cpuarm) or defined(cpuaarch64)}  // need a lower latency
          uos_AddIntoDevOut(0, -1, 0.3, -1, -1, -1, -1, -1);
       {$else}
          uos_AddIntoDevOut(0, -1, -1, -1, -1, -1, -1, -1);
       {$endif}
       uos_Play(0, MAXINT);
     end;
end;

//
//
//   РАБОТА С ГРАФИКОЙ
//
//

// Рассчет размера кубов в игре
procedure CalcCubeSize(Sender: TObject);
begin
     CubeSize := Form1.Height div 6;
end;

// Отобразить метровую сетку
procedure ShowCudes();
var
  i : Integer;
begin
     Form1.Canvas.Brush.Color:= clBlack;

     // Горизонталь
     i := 0;
     while i <= Form1.Height do
     begin
          Form1.Canvas.Line(0, i, Form1.Width, i);
          i := i + CubeSize;
     end;

     // Вертикаль
     i := 0;
     while i <= Form1.Width do
     begin
          Form1.Canvas.Line(i, 0, i, Form1.Height);
          i := i + CubeSize;
     end;
end;

// Загрузка текстур
function LoadTexture (filename : string)  : integer;
var
 texID : Integer;
 img : TBitmap;

begin

  img := TBitmap.Create();
  img.LoadFromFile(TMPDir +  DirectorySeparator + 'assets' +  DirectorySeparator + 'textures' +  DirectorySeparator + filename);
  glGenTextures( 1, @texID);
  glBindTexture(GL_TEXTURE_2D, texID);
  glTexImage2D(GL_TEXTURE_2D , 0, GL_RGB, img.Width, img.Height, 0, GL_RGB, GL_UNSIGNED_BYTE, img.RawImage.Data);
  img.Free;
  Result := texID;
end;

//
//
//   РАБОТА С ФОРМОЙ
//
//

procedure TForm1.Button1Click(Sender: TObject);
begin

end;

// Событие при запуске программы
procedure TForm1.FormCreate(Sender: TObject);
begin
     // Распаковка ресурсов приожения
     CreateTMPDir();
     UnpackLibs();
     UnpackAssets();

     // Загрузка библиотек
     LoadLibs();

     // Запуск музыки
     PlayMusicBG();

     // Загрузка текстур
     //texi := LoadTexture('grass.bmp');
     //Form1.OpenGLControl1.Repaint;

end;

procedure TForm1.FormResize(Sender: TObject);
begin
     // Запуск отрисовки
     CalcCubeSize(Self);
     ShowCudes();
end;



procedure TForm1.OpenGLControl1Paint(Sender: TObject);
var
  x, y : Integer;
   texID : Integer;
 img : TBitmap;
begin
  Randomize();
  // Запуск отрисовки
  CalcCubeSize(Self);

  img := TBitmap.Create();
  img.LoadFromFile(TMPDir +  DirectorySeparator + 'assets' +  DirectorySeparator + 'textures' +  DirectorySeparator + 'grass.bmp');
  glGenTextures(1, @texID);
  glBindTexture(GL_TEXTURE_2D, texID);
  glTexImage2D(GL_TEXTURE_2D , 0, GL_RGB, img.Width, img.Height, 0, GL_BITMAP, GL_UNSIGNED_BYTE, img.RawImage.Data);
  img.Free;
  texi := texID;

  glClearColor(0.27, 0.53, 0.71, 1.0); // Задаем синий фон
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glOrtho(0.0, Form1.Width, 0.0, Form1.Height, -1.0, 1.0);
  glEnable(GL_POINT_SMOOTH);



  x := 0;
  while x < Form1.Width do
  begin
    y := 0;
    while y < Form1.Height do
    begin
        //glBindTexture(Gl.GL_TEXTURE_2D, texi);
        glBegin(GL_QUADS);
        //glColor3f(1, 0, 0);
        glTexCoord2f(0.0, 1.0);
        glVertex2f(x+CubeSize, y);
        //glColor3f(0, 1, 0);
        glTexCoord2f(0.0, 0.0);
        glVertex2f(x, y);
        //glColor3f(0, 1, 0);
        glTexCoord2f(1.0, 0.0);
        glVertex2f(x, y+CubeSize);
        //glColor3f(0, 0, 1);
        glTexCoord2f(1.0, 1.0);
        glVertex2f(x+CubeSize, y+CubeSize);
        glEnd;
        y := y + CubeSize;
    end;
    x := x + CubeSize;
  end;


  glFlush;

  Form1.OpenGLControl1.SwapBuffers;
end;

end.

